#![cfg(target_os = "android")]

use std::ffi::CStr;
use std::fs;
use std::os::fd::RawFd;
use std::ptr;
use std::sync::Once;
use std::sync::atomic::{AtomicI32, Ordering};

const FMAC_MAX_DATA: usize = 64 * 1024;
const FMAC_STACK_DATA: usize = 264;

const IOC_CMD: libc::c_int = 0xC008_4600u32 as libc::c_int;
const IOC_GET_VERSION: u32 = 14;

const PR_GET_SHM_FD: libc::c_int = 201;
const PR_GET_CTL_FD: libc::c_int = 203;

static LOGGER: Once = Once::new();
static DRIVER_FD: AtomicI32 = AtomicI32::new(-1);
static CTL_FD: AtomicI32 = AtomicI32::new(-1);

fn init_logging() {
    LOGGER.call_once(|| {
        android_logger::init_once(
            android_logger::Config::default()
                .with_max_level(log::LevelFilter::Info)
                .with_tag("ncore"),
        );
    });
}

fn scan_fd(target: &str) -> RawFd {
    let Ok(entries) = fs::read_dir("/proc/self/fd") else {
        return -1;
    };
    for entry in entries.flatten() {
        let Ok(fd) = entry.file_name().to_string_lossy().parse::<i32>() else {
            continue;
        };
        let link = format!("/proc/self/fd/{fd}");
        if let Ok(path) = fs::read_link(link)
            && path.to_string_lossy().contains(target)
        {
            return fd;
        }
    }
    -1
}

fn ensure_ctl_fd() -> Option<RawFd> {
    let cached = CTL_FD.load(Ordering::Relaxed);
    if cached >= 0 {
        return Some(cached);
    }
    unsafe {
        libc::prctl(PR_GET_CTL_FD, 0, 0, 0, 0);
    }
    let fd = scan_fd("[fmac_ctl]");
    if fd >= 0 {
        CTL_FD.store(fd, Ordering::Relaxed);
        Some(fd)
    } else {
        log::error!("control fd not found after prctl({PR_GET_CTL_FD})");
        None
    }
}

fn ioc_call(fd: RawFd, flag: u32, data: &mut [u8]) -> i32 {
    if data.len() > FMAC_MAX_DATA {
        return -1;
    }
    let total = 8 + data.len();
    let mut stack = [0u8; 8 + FMAC_STACK_DATA];
    let mut heap = Vec::new();
    let buffer: &mut [u8] = if total <= stack.len() {
        &mut stack[..total]
    } else {
        heap.resize(total, 0);
        &mut heap
    };
    buffer[0..4].copy_from_slice(&flag.to_ne_bytes());
    buffer[4..8].copy_from_slice(&(data.len() as u32).to_ne_bytes());
    buffer[8..].copy_from_slice(data);

    let ret = unsafe { libc::ioctl(fd, IOC_CMD, buffer.as_mut_ptr()) };
    if ret < 0 {
        log::error!(
            "ioctl flag {flag} failed: {}",
            std::io::Error::last_os_error()
        );
    } else if !data.is_empty() {
        data.copy_from_slice(&buffer[8..]);
    }
    ret
}

fn ctl_impl(value: i32) -> i32 {
    log::info!("ctl({value})");
    match value {
        1 => {
            unsafe {
                libc::prctl(PR_GET_SHM_FD, 0, 0, 0, 0);
            }
            let fd = scan_fd("[fmac_shm]");
            if fd >= 0 {
                DRIVER_FD.store(fd, Ordering::Relaxed);
            }
        }
        3 => {
            ensure_ctl_fd();
        }
        _ => return -1,
    }
    if DRIVER_FD.load(Ordering::Relaxed) >= 0 {
        0
    } else {
        -1
    }
}

fn parse_gki(release: &str) -> Option<(bool, String)> {
    let mut parts = release.split('.');
    let major: i32 = parts.next()?.parse().ok()?;
    let minor_part = parts.next()?;
    let minor: i32 = minor_part
        .split(|c: char| !c.is_ascii_digit())
        .next()?
        .parse()
        .ok()?;
    let mut gki = false;
    if let Some(tag) = release.find("-android") {
        let rest = &release[tag + "-android".len()..];
        let digits: String = rest.chars().take_while(|c| c.is_ascii_digit()).collect();
        if !digits.is_empty() {
            let after = &rest[digits.len()..];
            if let Some(after) = after.strip_prefix('-')
                && after.chars().next().is_some_and(|c| c.is_ascii_digit())
            {
                gki = true;
            }
        }
    }
    Some((gki, format!("{major}.{minor:02}")))
}

fn uname_release() -> Option<String> {
    let mut uts: libc::utsname = unsafe { std::mem::zeroed() };
    if unsafe { libc::uname(&mut uts) } != 0 {
        return None;
    }
    let release = unsafe { CStr::from_ptr(uts.release.as_ptr()) };
    Some(release.to_string_lossy().into_owned())
}

fn module_version() -> Option<String> {
    let fd = ensure_ctl_fd()?;
    let mut data = [0u8; 64];
    if ioc_call(fd, IOC_GET_VERSION, &mut data) < 0 {
        return None;
    }
    let end = data
        .iter()
        .position(|byte| *byte == 0)
        .unwrap_or(data.len());
    Some(String::from_utf8_lossy(&data[..end]).into_owned())
}

fn copy_string(value: Option<String>, buffer: *mut u8, capacity: usize) -> isize {
    let Some(value) = value else {
        return -1;
    };
    let bytes = value.as_bytes();
    if buffer.is_null() {
        return -1;
    }
    if capacity <= bytes.len() {
        return bytes.len() as isize;
    }
    unsafe {
        ptr::copy_nonoverlapping(bytes.as_ptr(), buffer, bytes.len());
        *buffer.add(bytes.len()) = 0;
    }
    bytes.len() as isize
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_init() -> i32 {
    init_logging();
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_ctl(value: i32) -> i32 {
    init_logging();
    ctl_impl(value)
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_is_gki() -> i32 {
    init_logging();
    uname_release()
        .and_then(|release| parse_gki(&release))
        .map(|(gki, _)| if gki { 1 } else { 0 })
        .unwrap_or(-1)
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_kernel_version(buffer: *mut u8, capacity: usize) -> isize {
    init_logging();
    let version = uname_release()
        .and_then(|release| parse_gki(&release))
        .map(|(_, version)| version);
    copy_string(version, buffer, capacity)
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_kernel_release(buffer: *mut u8, capacity: usize) -> isize {
    init_logging();
    copy_string(uname_release(), buffer, capacity)
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_module_version(buffer: *mut u8, capacity: usize) -> isize {
    init_logging();
    copy_string(module_version(), buffer, capacity)
}

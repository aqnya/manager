#![cfg(target_os = "android")]

use std::ffi::CStr;
use std::fs;
use std::os::fd::RawFd;
use std::ptr;
use std::slice;
use std::sync::Once;
use std::sync::atomic::{AtomicI32, Ordering};

const FMAC_MAX_DATA: usize = 64 * 1024;
const FMAC_STACK_DATA: usize = 264;

const FMAC_DATA_PROFILE: usize = 84;
const FMAC_OFF_UID: usize = 0;
const FMAC_OFF_CAPS: usize = 4;
const FMAC_OFF_DOMAIN: usize = 12;
const FMAC_OFF_NS: usize = 76;
const FMAC_OFF_ROOT_UID: usize = 80;

const IOC_CMD: libc::c_int = 0xC008_4600u32 as libc::c_int;
const IOC_DEL_UID: u32 = 4;
const IOC_HAS_UID: u32 = 5;
const IOC_SET_PROFILE: u32 = 10;
const IOC_GET_PROFILES: u32 = 13;
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

fn set_profile_impl(uid: i32, root_uid: i32, caps: u64, domain: &[u8], namespace: i32) -> i32 {
    if uid < 0 || root_uid < 0 || namespace <= 0 {
        return -1;
    }
    let Some(fd) = ensure_ctl_fd() else {
        return -1;
    };

    let mut data = [0u8; FMAC_DATA_PROFILE];
    data[FMAC_OFF_UID..FMAC_OFF_UID + 4].copy_from_slice(&(uid as u32).to_ne_bytes());
    data[FMAC_OFF_CAPS..FMAC_OFF_CAPS + 8].copy_from_slice(&caps.to_ne_bytes());
    let len = domain.len().min(FMAC_OFF_NS - FMAC_OFF_DOMAIN - 1);
    data[FMAC_OFF_DOMAIN..FMAC_OFF_DOMAIN + len].copy_from_slice(&domain[..len]);
    data[FMAC_OFF_NS..FMAC_OFF_NS + 4].copy_from_slice(&namespace.to_ne_bytes());
    data[FMAC_OFF_ROOT_UID..FMAC_OFF_ROOT_UID + 4]
        .copy_from_slice(&(root_uid as u32).to_ne_bytes());

    if ioc_call(fd, IOC_SET_PROFILE, &mut data) < 0 {
        -1
    } else {
        0
    }
}

fn uid_ioctl(uid: i32, flag: u32) -> i32 {
    if uid < 0 {
        return -1;
    }
    let Some(fd) = ensure_ctl_fd() else {
        return -1;
    };
    let mut data = (uid as u32).to_ne_bytes();
    if ioc_call(fd, flag, &mut data) < 0 {
        -1
    } else {
        0
    }
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

#[unsafe(no_mangle)]
pub extern "C" fn ncore_set_profile(
    uid: i32,
    root_uid: i32,
    caps: u64,
    domain: *const u8,
    domain_len: usize,
    namespace: i32,
) -> i32 {
    init_logging();
    if domain_len > 4096 || (domain.is_null() && domain_len != 0) {
        return -1;
    }
    let domain = if domain_len == 0 {
        &[]
    } else {
        unsafe { slice::from_raw_parts(domain, domain_len) }
    };
    set_profile_impl(uid, root_uid, caps, domain, namespace)
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_del_uid(uid: i32) -> i32 {
    init_logging();
    uid_ioctl(uid, IOC_DEL_UID)
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_has_uid(uid: i32) -> i32 {
    init_logging();
    if uid < 0 {
        return -1;
    }
    let Some(fd) = ensure_ctl_fd() else {
        return -1;
    };
    let mut data = (uid as u32).to_ne_bytes();
    if ioc_call(fd, IOC_HAS_UID, &mut data) < 0 {
        return -1;
    }
    if u32::from_ne_bytes(data) != 0 { 1 } else { 0 }
}

#[unsafe(no_mangle)]
pub extern "C" fn ncore_list_profiles(buffer: *mut u8, capacity: usize) -> isize {
    init_logging();
    let Some(fd) = ensure_ctl_fd() else {
        return -1;
    };
    let mut data = vec![0u8; FMAC_MAX_DATA];
    if ioc_call(fd, IOC_GET_PROFILES, &mut data) < 0 {
        return -1;
    }
    let end = data
        .iter()
        .position(|byte| *byte == 0)
        .unwrap_or(data.len());
    copy_string(
        Some(String::from_utf8_lossy(&data[..end]).into_owned()),
        buffer,
        capacity,
    )
}

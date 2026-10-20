package com.example.nekosu

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.LruCache
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.min
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "nekosu/apps"
        const val MAX_ICON_SIZE = 160
        const val MIUI_APPS_PERMISSION = "com.android.permission.GET_INSTALLED_APPS"
        const val MIUI_SECURITY_PACKAGE = "com.lbe.security.miui"
        const val MIUI_PERMISSION_REQUEST = 4102
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val iconCache =
        object : LruCache<String, ByteArray>(8 * 1024 * 1024) {
            override fun sizeOf(
                key: String,
                value: ByteArray,
            ): Int = value.size
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "listApps" -> runAsync(result) { listApps() }
                "getIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrEmpty()) {
                        result.error("invalid_argument", "packageName is required", null)
                    } else {
                        runAsync(result) { getIcon(packageName) }
                    }
                }
                else -> result.notImplemented()
            }
        }

        mainHandler.postDelayed({ requestMiuiAppListPermission() }, 300)
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }

    private fun <T> runAsync(
        result: MethodChannel.Result,
        block: () -> T,
    ) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("app_query_failed", error.message ?: "App query failed", null)
                }
            }
        }
    }

    private fun listApps(): List<Map<String, Any>> {
        val pm = packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(launcherIntent, PackageManager.ResolveInfoFlags.of(0L))
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(launcherIntent, 0)
            }
        val launchable = resolved.mapNotNullTo(HashSet<String>()) { it.activityInfo?.packageName }

        val apps = ArrayList<Map<String, Any>>()
        for (pkg in pm.getInstalledPackages(0)) {
            val info = pkg.applicationInfo ?: continue
            val label = info.loadLabel(pm).toString().ifBlank { pkg.packageName }
            apps +=
                mapOf(
                    "name" to label,
                    "packageName" to pkg.packageName,
                    "uid" to info.uid,
                    "isSystem" to ((info.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                    "isLaunchable" to launchable.contains(pkg.packageName),
                )
        }
        return apps
    }

    private fun requestMiuiAppListPermission() {
        if (isFinishing || isDestroyed) return
        val permissionInfo =
            try {
                packageManager.getPermissionInfo(MIUI_APPS_PERMISSION, 0)
            } catch (_: PackageManager.NameNotFoundException) {
                return
            }
        if (permissionInfo.packageName != MIUI_SECURITY_PACKAGE) return
        if (checkSelfPermission(MIUI_APPS_PERMISSION) == PackageManager.PERMISSION_GRANTED) return
        try {
            requestPermissions(arrayOf(MIUI_APPS_PERMISSION), MIUI_PERMISSION_REQUEST)
        } catch (_: Exception) {}
    }

    private fun getIcon(packageName: String): ByteArray {
        iconCache.get(packageName)?.let { return it }

        val drawable = packageManager.getApplicationIcon(packageName)
        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: MAX_ICON_SIZE
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: MAX_ICON_SIZE
        val scale = min(1f, MAX_ICON_SIZE.toFloat() / maxOf(width, height))
        val outWidth = maxOf(1, (width * scale).roundToInt())
        val outHeight = maxOf(1, (height * scale).roundToInt())

        val bitmap = Bitmap.createBitmap(outWidth, outHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, outWidth, outHeight)
        drawable.draw(canvas)

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        bitmap.recycle()
        val bytes = stream.toByteArray()
        iconCache.put(packageName, bytes)
        return bytes
    }
}

package com.example.nekosu

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Platform-only helpers for the FFI-backed module screen.
 *
 * Module state and commands are handled by ncore_ffi; this bridge only opens
 * Android's document picker, stages the selected ZIP in the app cache and
 * launches the WebView activity for an already-prepared webroot.
 */
class ModuleBridge(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger,
) {
    private companion object {
        const val CHANNEL = "nekosu/modules_platform"
        const val PICK_ZIP_REQUEST = 4210
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingPickerResult: MethodChannel.Result? = null

    fun register() {
        channel.setMethodCallHandler(::onMethodCall)
    }

    fun dispose() {
        pendingPickerResult = null
        channel.setMethodCallHandler(null)
        executor.shutdownNow()
    }

    fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != PICK_ZIP_REQUEST) return false
        val result = pendingPickerResult ?: return true
        pendingPickerResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        stageZip(result, uri)
        return true
    }

    private fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "pickZip" -> pickZip(result)
            "openWebUi" -> openWebUi(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickZip(result: MethodChannel.Result) {
        if (pendingPickerResult != null) {
            result.error("picker_busy", "The document picker is already open", null)
            return
        }
        pendingPickerResult = result
        val intent =
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf("application/zip", "application/octet-stream"),
                )
            }
        try {
            activity.startActivityForResult(intent, PICK_ZIP_REQUEST)
        } catch (error: Exception) {
            pendingPickerResult = null
            result.error("picker_failed", error.message ?: "Unable to open document picker", null)
        }
    }

    private fun stageZip(
        result: MethodChannel.Result,
        uri: Uri,
    ) {
        executor.execute {
            try {
                val file = File(activity.cacheDir, "module-install.zip")
                activity.contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) { "Unable to open the selected archive" }
                    file.outputStream().use { output -> input.copyTo(output) }
                }
                activity.runOnUiThread { result.success(file.absolutePath) }
            } catch (error: Exception) {
                activity.runOnUiThread {
                    result.error(
                        "picker_copy_failed",
                        error.message ?: "Unable to stage module archive",
                        null,
                    )
                }
            }
        }
    }

    private fun openWebUi(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val path = call.argument<String>("path")
        if (path.isNullOrBlank() || !File(path).isFile) {
            result.error("webui_missing", "WebUI entry file is unavailable", null)
            return
        }
        try {
            activity.startActivity(
                Intent(activity, ModuleWebUiActivity::class.java)
                    .putExtra(ModuleWebUiActivity.EXTRA_FILE, path),
            )
            result.success(true)
        } catch (error: Exception) {
            result.error("webui_failed", error.message ?: "Unable to open WebUI", null)
        }
    }
}

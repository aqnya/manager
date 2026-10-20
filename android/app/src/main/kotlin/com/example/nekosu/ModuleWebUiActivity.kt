package com.example.nekosu

import android.app.Activity
import android.net.Uri
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import java.io.File

/** Minimal, sandboxed WebView host for a module's copied webroot. */
class ModuleWebUiActivity : Activity() {
    companion object {
        const val EXTRA_FILE = "module_webui_file"
    }

    private var webView: WebView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val file = intent.getStringExtra(EXTRA_FILE)
        if (file.isNullOrBlank() || !File(file).isFile) {
            finish()
            return
        }

        val view =
            WebView(this).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.allowFileAccess = true
                settings.allowContentAccess = false
                webViewClient = WebViewClient()
                loadUrl(Uri.fromFile(File(file)).toString())
            }
        webView = view
        setContentView(view)
    }

    @Deprecated("Deprecated in Activity, but retained for WebView back navigation")
    override fun onBackPressed() {
        val view = webView
        if (view != null && view.canGoBack()) {
            view.goBack()
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        webView?.apply {
            stopLoading()
            destroy()
        }
        webView = null
        super.onDestroy()
    }
}

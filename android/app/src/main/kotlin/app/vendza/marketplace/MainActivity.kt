package app.vendza.marketplace

import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "app.vendza.marketplace/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "shareProduct") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val phone = call.argument<String>("phone").orEmpty()
                val text = call.argument<String>("text").orEmpty()
                val filePath = call.argument<String>("filePath")
                try {
                    shareToWhatsApp(phone, text, filePath)
                    result.success(true)
                } catch (error: Exception) {
                    result.error("whatsapp_share_failed", error.message, null)
                }
            }
    }

    private fun shareToWhatsApp(phone: String, text: String, filePath: String?) {
        val targetPackage =
            listOf("com.whatsapp", "com.whatsapp.w4b").firstOrNull(::isInstalled)
                ?: throw IllegalStateException("WhatsApp is not installed")

        val intent = Intent(Intent.ACTION_SEND).apply {
            setPackage(targetPackage)
            putExtra("jid", "$phone@s.whatsapp.net")
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val file = filePath?.let(::File)
        if (file != null && file.exists()) {
            val uri: Uri =
                FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            intent.type = "image/*"
            intent.putExtra(Intent.EXTRA_STREAM, uri)
            intent.clipData = ClipData.newRawUri("", uri)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } else {
            intent.type = "text/plain"
        }

        startActivity(intent)
    }

    private fun isInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}

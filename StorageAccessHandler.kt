package com.allwhtsappstatus_saver

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import androidx.core.content.ContextCompat
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.IOException
import android.util.Log

class StorageAccessHandler(private val context: Context) {
    companion object {
        private const val WHATSAPP_MEDIA_PATH = "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"
        private const val WHATSAPP_BUSINESS_PATH = "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"
        private const val LEGACY_WHATSAPP_PATH = "WhatsApp/Media/.Statuses"
        private const val LEGACY_WHATSAPP_BUSINESS_PATH = "WhatsApp Business/Media/.Statuses"
        private const val APP_FOLDER_NAME = "StatusSaver"
    }

    fun hasRequiredPermissions(): Boolean {
        val hasStoragePermission = Environment.isExternalStorageManager()
        
        val hasMediaPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                android.Manifest.permission.READ_MEDIA_IMAGES,
                android.Manifest.permission.READ_MEDIA_VIDEO
            ).all {
                ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
            }
        } else {
            arrayOf(
                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            ).all {
                ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
            }
        }

        val hasSafAccess = getStatusDirectoryUri() != null

        Log.d("StorageAccessHandler", "Permissions check: storage=$hasStoragePermission, media=$hasMediaPermissions, saf=$hasSafAccess")
        return hasStoragePermission && hasMediaPermissions && hasSafAccess
    }

    fun getStatusDirectoryUri(isBusinessWhatsApp: Boolean = false): Uri? {
        return context.getSharedPreferences("storage_prefs", Context.MODE_PRIVATE)
            .getString(if (isBusinessWhatsApp) "business_uri" else "whatsapp_uri", null)
            ?.let { Uri.parse(it) }
    }

    fun handleDirectorySelection(uri: Uri, isBusinessWhatsApp: Boolean = false) {
        context.getSharedPreferences("storage_prefs", Context.MODE_PRIVATE)
            .edit()
            .putString(if (isBusinessWhatsApp) "business_uri" else "whatsapp_uri", uri.toString())
            .apply()
    }

    fun getStatusFiles(isBusinessWhatsApp: Boolean = false): List<StatusFileInfo> {
        if (!hasRequiredPermissions()) return emptyList()

        val uri = getStatusDirectoryUri(isBusinessWhatsApp) ?: return emptyList()
        val directory = DocumentFile.fromTreeUri(context, uri) ?: return emptyList()
        
        return directory.listFiles()
            .filter { file ->
                file.isFile && (file.name?.matches(Regex(".*\\.(jpg|mp4)$")) == true)
            }
            .map { file ->
                StatusFileInfo(
                    uri = file.uri,
                    name = file.name ?: "",
                    isVideo = file.type?.contains("video") == true,
                    dateModified = file.lastModified(),
                    size = file.length()
                )
            }
    }

    fun checkFileExists(path: String): Boolean {
        return try {
            File(path).exists()
        } catch (e: Exception) {
            false
        }
    }

    @Throws(IOException::class)
    fun saveFile(sourceUri: Uri, fileName: String, isVideo: Boolean): Boolean {
        var inputStream: InputStream? = null
        var outputStream: FileOutputStream? = null
        
        try {
            val downloadPath = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                ?: return false
                
            val appFolder = File(downloadPath, APP_FOLDER_NAME)
            if (!appFolder.exists()) {
                val created = appFolder.mkdirs()
                if (!created) return false
            }

            val destinationFile = File(appFolder, fileName)
            
            inputStream = context.contentResolver.openInputStream(sourceUri)
                ?: return false
                
            outputStream = FileOutputStream(destinationFile)
            
            val buffer = ByteArray(8 * 1024)
            var read: Int
            while (inputStream.read(buffer).also { read = it } != -1) {
                outputStream.write(buffer, 0, read)
            }
            
            outputStream.flush()
            return true
            
        } catch (e: Exception) {
            Log.e("StorageAccessHandler", "Error saving file", e)
            return false
        } finally {
            try {
                inputStream?.close()
                outputStream?.close()
            } catch (e: Exception) {
                Log.e("StorageAccessHandler", "Error closing streams", e)
            }
        }
    }
}

data class StatusFileInfo(
    val uri: Uri,
    val name: String,
    val isVideo: Boolean,
    val dateModified: Long,
    val size: Long
)
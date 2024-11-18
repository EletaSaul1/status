package com.allwhtsappstatus_saver

import android.content.Intent
import android.os.Build
import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.allwhtsappstatus_saver/storage"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkStorageAccess" -> {
                    val hasPermissions = checkPermissions()
                    val hasSafAccess = checkSafAccess()
                    Log.d("MainActivity", "Storage check - Permissions: $hasPermissions, SAF: $hasSafAccess")
                    result.success(hasPermissions && hasSafAccess)
                }
                "requestAllPermissions" -> {
                    pendingResult = result
                    if (!checkPermissions()) {
                        requestMediaPermissions()
                    } else if (!checkSafAccess()) {
                        requestSafAccess()
                    } else {
                        result.success(true)
                    }
                }
                "getStatuses" -> {
                    try {
                        if (!checkSafAccess()) {
                            requestSafAccess()
                            result.success(emptyList<Map<String, Any>>())
                            return@setMethodCallHandler
                        }
                        
                        val statuses = getStatusesFromSaf()
                        Log.d("MainActivity", "Found ${statuses.size} total statuses")
                        result.success(statuses)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error getting statuses", e)
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkPermission(Manifest.permission.READ_MEDIA_IMAGES) &&
            checkPermission(Manifest.permission.READ_MEDIA_VIDEO)
        } else {
            checkPermission(Manifest.permission.READ_EXTERNAL_STORAGE) &&
            checkPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
    }

    private fun checkPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestMediaPermissions() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_CODE)
    }

    private fun requestSafAccess() {
        try {
            val initialUri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fmedia")
            
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            }
            startActivityForResult(intent, SAF_REQUEST_CODE)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error requesting SAF access", e)
            pendingResult?.success(false)
            pendingResult = null
        }
    }

    private fun checkSafAccess(): Boolean {
        val prefs = getSharedPreferences("storage_prefs", MODE_PRIVATE)
        val treeUri = prefs.getString("tree_uri", null) ?: return false
        
        try {
            val uri = Uri.parse(treeUri)
            // Check if we still have the permissions
            contentResolver.persistedUriPermissions.forEach { permission ->
                if (permission.uri == uri && permission.isReadPermission && permission.isWritePermission) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking SAF access", e)
        }
        
        return false
    }

    private fun getStatusesFromSaf(): List<Map<String, Any>> {
        val prefs = getSharedPreferences("storage_prefs", MODE_PRIVATE)
        val treeUriStr = prefs.getString("tree_uri", null) ?: return emptyList()
        val rootDoc = DocumentFile.fromTreeUri(this, Uri.parse(treeUriStr)) ?: return emptyList()
        val statuses = mutableListOf<Map<String, Any>>()

        // Look for both WhatsApp and WhatsApp Business statuses
        fun searchForStatuses(doc: DocumentFile, currentPath: String = "") {
            try {
                doc.listFiles().forEach { file ->
                    if (file.isDirectory) {
                        searchForStatuses(file, "$currentPath/${file.name}")
                    } else if (file.isFile && 
                             file.name?.matches(Regex(".*\\.(jpg|mp4)$")) == true && 
                             currentPath.contains(".Statuses")) {
                        
                        val isVideo = file.type?.contains("video") == true
                        val appSource = when {
                            currentPath.contains("com.whatsapp.w4b") || 
                            currentPath.contains("WhatsApp Business") -> "WhatsApp Business"
                            else -> "WhatsApp"
                        }

                        statuses.add(mapOf(
                            "path" to file.uri.toString(),
                            "dateModified" to file.lastModified(),
                            "isVideo" to isVideo,
                            "name" to (file.name ?: ""),
                            "appSource" to appSource,
                            "mediaType" to if (isVideo) "video" else "image"
                        ))
                    }
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error reading path: $currentPath", e)
            }
        }

        searchForStatuses(rootDoc)
        return statuses
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == SAF_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data?.data != null) {
                val uri = data.data!!
                Log.d("MainActivity", "Got SAF permission for URI: $uri")

                try {
                    val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                  Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    contentResolver.takePersistableUriPermission(uri, takeFlags)

                    getSharedPreferences("storage_prefs", MODE_PRIVATE)
                        .edit()
                        .putString("tree_uri", uri.toString())
                        .apply()

                    pendingResult?.success(true)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error saving SAF permission", e)
                    pendingResult?.success(false)
                }
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_CODE) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                requestSafAccess()
            } else {
                pendingResult?.success(false)
                pendingResult = null
            }
        }
    }

    companion object {
        private const val SAF_REQUEST_CODE = 1001
        private const val PERMISSION_CODE = 1002
    }
}
package com.coffee.timer

import android.Manifest
import android.app.AlarmManager
import android.content.ComponentName
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity: FlutterActivity() {
    private val ICON_CHANNEL = "com.coffee.timer/icon"
    private val EXACT_ALARM_CHANNEL = "com.coffee.timer/exact_alarm"
    private val LIVE_UPDATES_CHANNEL = "com.coffee.timer/live_updates"
    private val PHOTO_LIBRARY_CHANNEL = "com.coffee.timer/photo_library"
    private val PHOTO_LIBRARY_PERMISSION_REQUEST = 7042

    private lateinit var brewingLiveUpdateService: BrewingLiveUpdateService
    private var pendingPhotoSaveRequest: PendingPhotoSaveRequest? = null

    private data class PendingPhotoSaveRequest(
        val paths: List<String>,
        val result: MethodChannel.Result
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        brewingLiveUpdateService = BrewingLiveUpdateService(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ICON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentIcon" -> {
                    result.success(getCurrentActiveIcon())
                }
                "setIcon" -> {
                    val iconName = call.argument<String>("iconName")
                    val success = setActiveIcon(iconName)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXACT_ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canScheduleExactAlarms" -> {
                    result.success(canScheduleExactAlarms())
                }
                "requestExactAlarmPermission" -> {
                    result.success(requestExactAlarmPermission())
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_UPDATES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(brewingLiveUpdateService.canUseLiveUpdates())
                }
                "startBrewing" -> {
                    try {
                        val data = call.arguments as? Map<String, Any> ?: emptyMap()
                        brewingLiveUpdateService.startBrewingNotification(data)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "updateBrewing" -> {
                    try {
                        val data = call.arguments as? Map<String, Any> ?: emptyMap()
                        brewingLiveUpdateService.updateBrewingNotification(data)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UPDATE_FAILED", e.message, null)
                    }
                }
                "endBrewing" -> {
                    try {
                        brewingLiveUpdateService.endBrewingNotification()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("END_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHOTO_LIBRARY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "saveImages") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val rawPaths = call.argument<List<*>>("paths")
            val paths = rawPaths?.filterIsInstance<String>()
            if (
                rawPaths == null ||
                paths == null ||
                paths.isEmpty() ||
                paths.size != rawPaths.size
            ) {
                result.success(photoLibraryResult("failed", 0, rawPaths?.size ?: 0))
                return@setMethodCallHandler
            }

            handlePhotoLibrarySave(paths, result)
        }
    }

    private fun handlePhotoLibrarySave(paths: List<String>, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.success(photoLibraryResult("unsupported", 0, paths.size))
            return
        }

        if (
            Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingPhotoSaveRequest != null) {
                result.error("ALREADY_ACTIVE", "A photo save request is already pending", null)
                return
            }
            pendingPhotoSaveRequest = PendingPhotoSaveRequest(paths, result)
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                PHOTO_LIBRARY_PERMISSION_REQUEST
            )
            return
        }

        saveImagesToPhotoLibrary(paths, result)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PHOTO_LIBRARY_PERMISSION_REQUEST) return

        val pendingRequest = pendingPhotoSaveRequest ?: return
        pendingPhotoSaveRequest = null
        if (
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            saveImagesToPhotoLibrary(pendingRequest.paths, pendingRequest.result)
        } else {
            pendingRequest.result.success(
                photoLibraryResult("denied", 0, pendingRequest.paths.size)
            )
        }
    }

    private fun saveImagesToPhotoLibrary(paths: List<String>, result: MethodChannel.Result) {
        Thread {
            var savedCount = 0
            for (path in paths) {
                val source = File(path)
                if (!source.isFile) continue

                val saved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    saveImageWithMediaStore(source)
                } else {
                    saveLegacyImage(source)
                }
                if (saved) savedCount++
            }

            val failedCount = paths.size - savedCount
            val status = when {
                failedCount == 0 -> "saved"
                savedCount == 0 -> "failed"
                else -> "partial"
            }
            val response = photoLibraryResult(status, savedCount, failedCount)
            runOnUiThread { result.success(response) }
        }.start()
    }

    @android.annotation.TargetApi(Build.VERSION_CODES.Q)
    private fun saveImageWithMediaStore(source: File): Boolean {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, source.name)
            put(MediaStore.Images.Media.MIME_TYPE, imageMimeType(source))
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/Timer.Coffee"
            )
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return false

        return try {
            resolver.openOutputStream(uri, "w")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IOException("Could not open photo destination")

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            if (resolver.update(uri, values, null, null) <= 0) {
                throw IOException("Could not publish photo")
            }
            true
        } catch (_: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun saveLegacyImage(source: File): Boolean {
        val picturesDirectory = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            "Timer.Coffee"
        )
        if (!picturesDirectory.exists() && !picturesDirectory.mkdirs()) return false

        val destination = uniqueDestinationFile(picturesDirectory, source)
        return try {
            source.inputStream().use { input ->
                destination.outputStream().use { output -> input.copyTo(output) }
            }
            MediaScannerConnection.scanFile(
                this,
                arrayOf(destination.absolutePath),
                arrayOf(imageMimeType(source)),
                null
            )
            true
        } catch (_: Exception) {
            if (destination.exists()) destination.delete()
            false
        }
    }

    private fun uniqueDestinationFile(directory: File, source: File): File {
        val requestedName = source.name.ifBlank { "scan_${System.currentTimeMillis()}.jpg" }
        val extensionIndex = requestedName.lastIndexOf('.')
        val baseName = if (extensionIndex > 0) {
            requestedName.substring(0, extensionIndex)
        } else {
            requestedName
        }
        val extension = if (extensionIndex > 0) {
            requestedName.substring(extensionIndex)
        } else {
            ""
        }

        var destination = File(directory, requestedName)
        var suffix = 1
        while (destination.exists()) {
            destination = File(directory, "${baseName}_$suffix$extension")
            suffix++
        }
        return destination
    }

    private fun imageMimeType(file: File): String {
        return MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(file.extension.lowercase()) ?: "image/jpeg"
    }

    private fun photoLibraryResult(
        status: String,
        savedCount: Int,
        failedCount: Int
    ): Map<String, Any> {
        return mapOf(
            "status" to status,
            "savedCount" to savedCount,
            "failedCount" to failedCount
        )
    }

    private fun getCurrentActiveIcon(): String {
        val packageManager = packageManager
        val packageName = packageName
        
        // Check which activity-alias is currently enabled
        val defaultComponent = ComponentName(packageName, "$packageName.Default")
        val legacyComponent = ComponentName(packageName, "$packageName.Legacy")
        
        val defaultState = packageManager.getComponentEnabledSetting(defaultComponent)
        val legacyState = packageManager.getComponentEnabledSetting(legacyComponent)
        
        println("DEBUG NATIVE: Default state: $defaultState, Legacy state: $legacyState")
        
        return when {
            legacyState == PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> "Legacy"
            defaultState == PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> "Default"
            defaultState == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> "Default" // Default is enabled by default
            else -> "Default"
        }
    }

    private fun setActiveIcon(iconName: String?): Boolean {
        return try {
            val packageManager = packageManager
            val packageName = packageName
            
            val defaultComponent = ComponentName(packageName, "$packageName.Default")
            val legacyComponent = ComponentName(packageName, "$packageName.Legacy")
            
            println("DEBUG NATIVE: Setting icon to: $iconName")
            
            when (iconName) {
                "Legacy" -> {
                    // Enable Legacy, disable Default
                    packageManager.setComponentEnabledSetting(
                        legacyComponent,
                        PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    packageManager.setComponentEnabledSetting(
                        defaultComponent,
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    println("DEBUG NATIVE: Legacy enabled, Default disabled")
                }
                "Default" -> {
                    // Enable Default, disable Legacy
                    packageManager.setComponentEnabledSetting(
                        defaultComponent,
                        PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    packageManager.setComponentEnabledSetting(
                        legacyComponent,
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    println("DEBUG NATIVE: Default enabled, Legacy disabled")
                }
                else -> return false
            }
            
            // Verify the change
            val newCurrentIcon = getCurrentActiveIcon()
            println("DEBUG NATIVE: After change, current icon is: $newCurrentIcon")
            
            true
        } catch (e: Exception) {
            println("DEBUG NATIVE: Error setting icon: ${e.message}")
            false
        }
    }

    // Exact alarm helpers ----------------------------------------------------
    private fun canScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(AlarmManager::class.java)
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun requestExactAlarmPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true

        val alarmManager = getSystemService(AlarmManager::class.java)
        if (alarmManager.canScheduleExactAlarms()) return true

        return try {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
            // We cannot know the result immediately; caller should re-check after user action.
            alarmManager.canScheduleExactAlarms()
        } catch (e: Exception) {
            println("DEBUG NATIVE: Error requesting exact alarm permission: ${e.message}")
            false
        }
    }
}

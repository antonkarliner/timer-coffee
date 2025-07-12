package com.coffee.timer

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.coffee.timer/icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
}

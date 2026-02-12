package com.coffee.timer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Manages Android 16+ Live Update notifications for the brewing timer.
 * Shows a promoted ongoing notification with countdown timer and progress bar.
 * No-ops on Android < 16 (API 36).
 */
class BrewingLiveUpdateService(private val context: Context) {

    companion object {
        private const val CHANNEL_ID = "brewing_timer"
        private const val NOTIFICATION_ID = 2001
        private const val API_36 = 36
    }

    private var isActive = false

    fun canUseLiveUpdates(): Boolean {
        return Build.VERSION.SDK_INT >= API_36
    }

    fun startBrewingNotification(data: Map<String, Any>) {
        if (Build.VERSION.SDK_INT < API_36) return
        ensureNotificationChannel()
        val notification = buildNotification(data)
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.notify(NOTIFICATION_ID, notification)
        isActive = true
    }

    fun updateBrewingNotification(data: Map<String, Any>) {
        if (!isActive || Build.VERSION.SDK_INT < API_36) return
        val notification = buildNotification(data)
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.notify(NOTIFICATION_ID, notification)
    }

    fun endBrewingNotification() {
        if (!isActive) return
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.cancel(NOTIFICATION_ID)
        isActive = false
    }

    private fun ensureNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Brewing Timer",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Shows brewing progress during active brew"
            enableVibration(false)
            setSound(null, null)
        }
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }

    private fun buildNotification(data: Map<String, Any>): Notification {
        val recipeName = data["recipeName"] as? String ?: ""
        val stepDescription = data["stepDescription"] as? String ?: ""
        val currentStep = (data["currentStep"] as? Number)?.toInt() ?: 1
        val totalSteps = (data["totalSteps"] as? Number)?.toInt() ?: 1
        val stepElapsedSeconds = (data["stepElapsedSeconds"] as? Number)?.toInt() ?: 0
        val stepTotalSeconds = (data["stepTotalSeconds"] as? Number)?.toInt() ?: 0
        val isPaused = (data["isPaused"] as? Number)?.toInt() == 1

        // Floor at 1 so the chronometer always has a future target and never
        // reaches zero (which causes it to count up). The 1-second overshoot is
        // imperceptible — the next tick either advances the step or sends a fresh update.
        val stepRemainingSeconds = maxOf(1, stepTotalSeconds - stepElapsedSeconds)
        val progress = if (stepTotalSeconds > 0) {
            ((stepElapsedSeconds.toFloat() / stepTotalSeconds) * 100).toInt().coerceIn(0, 99)
        } else 0

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(recipeName)
            .setContentText("Step $currentStep/$totalSteps · $stepDescription")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)

        if (!isPaused) {
            builder
                .setWhen(System.currentTimeMillis() + (stepRemainingSeconds * 1000L))
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setShowWhen(true)
        } else {
            builder
                .setUsesChronometer(false)
                .setShowWhen(false)
        }

        applyLiveUpdateStyle(builder, progress)

        return builder.build()
    }

    @Suppress("NewApi")
    private fun applyLiveUpdateStyle(builder: Notification.Builder, progress: Int) {
        if (Build.VERSION.SDK_INT < API_36) return
        builder.setStyle(
            Notification.ProgressStyle()
                .setProgress(progress)
        )
        builder.setFlag(Notification.FLAG_PROMOTED_ONGOING, true)
    }
}

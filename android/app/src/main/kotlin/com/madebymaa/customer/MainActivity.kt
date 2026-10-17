package com.madebymaa.customer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Stripe Payment Sheet requires AppCompat theme on the activity before plugins attach.
        setTheme(R.style.NormalTheme)
        createNotificationChannel()
        super.onCreate(savedInstanceState)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            "customer_orders",
            "Order updates",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Order status and delivery updates"
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}

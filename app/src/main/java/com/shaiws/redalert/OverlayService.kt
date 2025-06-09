package com.shaiws.redalert

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import okhttp3.*
import org.json.JSONException
import org.json.JSONObject
import com.shaiws.redalert.BuildConfig
import java.io.IOException
import com.shaiws.redalert.databinding.OverlayLayoutBinding

class OverlayService : Service() {
    private val client = OkHttpClient()
    private var items = listOf<String>()
    private var tmpItems = listOf<String>()
    private var modalTitle: String? = null

    private lateinit var binding: OverlayLayoutBinding

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View

    private val handler = Handler(Looper.getMainLooper())
    private var overlayDisplayed = false
    private var overlayDisplayDuration = 0L


    private val host: String =
        if (BuildConfig.DEBUG) "http://192.168.1.40:1337" else "https://www.oref.org.il"

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        binding = OverlayLayoutBinding.inflate(LayoutInflater.from(this))
        overlayView = binding.root

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.RIGHT or Gravity.TOP


        scheduleApiCall(params)
    }

    private fun scheduleApiCall(params: WindowManager.LayoutParams) {
        handler.postDelayed(object : Runnable {
            override fun run() {
                fetchItems {
                    Log.d("OverlayService", "Fetching items")
                    if (items.isNotEmpty() && items != tmpItems) {
                        tmpItems = items
                        displayOrUpdateOverlay(params)
                    }
                }
                overlayDisplayDuration += 1000L
                handler.postDelayed(this, 1000) // call API every second
            }
        }, 0)
    }

    private fun displayOrUpdateOverlay(
        params: WindowManager.LayoutParams
    ) {
        Log.d("OverlayService", "Checking overlay permission")
        if (Settings.canDrawOverlays(this)) {
            val linearLayout = binding.linearLayout
            linearLayout.removeAllViews()
            val titleTextView = binding.titleTextView
            titleTextView.text = modalTitle ?: "ירי רקטות וטילים"
            titleTextView.measure(0, 0)  // Measure titleTextView after setting text
            titleTextView.viewTreeObserver.addOnGlobalLayoutListener(object :
                ViewTreeObserver.OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    val totalTitleWidth = titleTextView.measuredWidth
                    val numberOfColumns =
                        (items.size + 14) / 15
                    for (i in 0 until numberOfColumns) {
                        val column = LinearLayout(this@OverlayService)
                        column.orientation = LinearLayout.VERTICAL
                        column.layoutParams = LinearLayout.LayoutParams(
                            totalTitleWidth,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        ).apply {
                            if (i > 0) rightMargin =
                                5  // Margin between columns for every column after the first one
                        }
                        linearLayout.addView(column, linearLayout.childCount)

                        val startIndex = i * 15
                        val endIndex = minOf(startIndex + 15, items.size)
                        for (j in startIndex until endIndex) {
                            val itemTextView = TextView(this@OverlayService)
                            itemTextView.text = items[j]
                            itemTextView.setShadowLayer(
                                1.5f,
                                0f,
                                1f,
                                Color.BLACK
                            )
                            itemTextView.setTextColor(Color.WHITE)
                            itemTextView.setBackgroundResource(R.drawable.gradient_background)
                            itemTextView.textSize = 16f
                            itemTextView.setTypeface(null, Typeface.BOLD)
                            itemTextView.setPadding(10, 2, 10, 2)
                            // Set the width of each item to be the same as the totalTitleWidth
                            val itemLayoutParams = LinearLayout.LayoutParams(
                                totalTitleWidth,
                                ViewGroup.LayoutParams.WRAP_CONTENT
                            ).apply {
                                topMargin = if (j == startIndex) 4 else 2
                                bottomMargin = 2

                            }

                            itemTextView.layoutParams = itemLayoutParams
                            column.addView(itemTextView)
                        }
                    }
                    titleTextView.viewTreeObserver.removeOnGlobalLayoutListener(this)
                }
            })

            items = items.sorted()

            if (!overlayDisplayed || overlayDisplayDuration > 20000) {
                overlayDisplayed = true
                overlayDisplayDuration = 0L

                try {
                    windowManager.addView(overlayView, params)
                } catch (e: Exception) {
                    // Handle exception
                }

                handler.postDelayed({
                    try {
                        windowManager.removeView(overlayView)
                        tmpItems = listOf()
                        overlayDisplayed = false
                    } catch (e: Exception) {
                        Log.e("OverlayService", "Error removing overlay", e)
                    }
                }, 20000)  // remove after 20 seconds
            }
        }
        else {
            Log.d("OverlayService", "Overlay permission not granted")
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.putExtra("fromOverlayService", true)
            intent.putExtra("items", items.toTypedArray())
            intent.putExtra("title", modalTitle)
            Log.d("OverlayService", "Extras: ${intent.extras}")
            startActivity(intent)
//            tmpItems = listOf()
        }
    }

    private fun fetchItems(callback: () -> Unit) {
        val request = Request.Builder()
            .url("$host/WarningMessages/alert/alerts.json")
            .addHeader("X-Requested-With", "XMLHttpRequest")
            .addHeader("Referer", "https://www.oref.org.il/")
            .cacheControl(
                CacheControl.Builder().noCache().build()
            ) // This line disables the caching
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                // Handle failure
            }

            override fun onResponse(call: Call, response: Response) {
                val jsonStr = response.body?.string()
                if (jsonStr == null || jsonStr.trim().isEmpty()) {
                    // Handle empty or null response
                    items = listOf()
                    modalTitle = null
                } else {
                    try {
                        val jsonObject = JSONObject(jsonStr)

                        val jsonArray = jsonObject.getJSONArray("data")
                        val tempItems = ArrayList<String>()
                        for (i in 0 until jsonArray.length()) {
                            val item = jsonArray.getString(i)
                            tempItems.add(item)
                        }
                        items = tempItems
                        modalTitle = jsonObject.getString("title")

                    } catch (e: JSONException) {
                        // Handle exception
                        Log.e("OverlayService", "Error parsing JSON: $jsonStr")
                    }
                }
                handler.post {
                    callback()
                }
            }

        })
    }

    private fun startForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "overlay",
                "Overlay Service",
                NotificationManager.IMPORTANCE_NONE
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "overlay")
            .setContentTitle("Overlay Service")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .build()

        startForeground(1, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
        windowManager.removeView(overlayView)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_DISPLAY_DUMMY -> {
                // Add dummy data to items list and display
                items = listOf(
                    resources.getString(R.string.test1),
                    resources.getString(R.string.test2),
                    resources.getString(R.string.test3),
                )
                modalTitle = resources.getString(R.string.thisIsATest)

                // You can directly call `displayOrUpdateOverlay` since you have dummy data
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                    PixelFormat.TRANSLUCENT
                )
                params.gravity = Gravity.RIGHT or Gravity.TOP
                displayOrUpdateOverlay(params)
            }

            else -> {
                // Handle other actions or default behavior
            }
        }
        return START_STICKY
    }


    companion object {
        private const val ACTION_DISPLAY_DUMMY = "ACTION_DISPLAY_DUMMY"
    }
}

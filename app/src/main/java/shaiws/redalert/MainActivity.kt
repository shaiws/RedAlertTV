package shaiws.redalert

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts

class MainActivity : AppCompatActivity() {

    private var isServiceBound = false
    private val overlayPermissionRequestCode = 0

    private var listDisplayed = false
    private var listDisplayDuration = 0L

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            isServiceBound = true
            displayStatus()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            isServiceBound = false
            displayStatus()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        startOverlayService()
        val testButton: Button = findViewById(R.id.testButton)
        testButton.setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                AlertDialog.Builder(this)
                    .setTitle("הרשאה להופיע מעל חלונות אחרים")
                    .setMessage(
                        "בכדי להציג התראות, האפליקציה דורשת הרשאה להופיע מעל חלונות אחרים. אנא עבור להגדרות המכשיר תחת\n" +
                                "'אפליקציות' -> 'גישה מיוחדת לאפליקציה' -> 'תצוגה מעל אפליקציות אחרות'\n" +
                                "ואשר את ההרשאה.\n" +
                                "לאחר מכן, הפעל את האפליקציה מחדש."
                    )
                    .setPositiveButton("אוקי") { dialog, _ -> dialog.dismiss() }
                    .show()
                displayListInApp(
                    "זוהי בדיקה               ",
                    listOf(
                        "זוהי בדיקה 1",
                        "זוהי בדיקה 2",
                        "זוהי בדיקה 3",
                        "ליעילות מיטבית יש לאשר את ההרשאות הנדרשות"
                    )
                )

            } else {
                val intent = Intent(this, OverlayService::class.java)
                intent.action = "ACTION_DISPLAY_DUMMY"
                startService(intent)
            }
        }
        testButton.requestFocus()

        val fromOverlayService = intent.getBooleanExtra("fromOverlayService", false)
        Log.d("MainActivity", "fromOverlayService: $fromOverlayService")
        if (fromOverlayService) {
            val title = intent.getStringExtra("title")
            val items = intent.getStringArrayExtra("items")?.toList()
            displayListInApp(title, items)

        } else {
            checkOverlayPermission()
            promptForBatteryOptimizationsPermission()
        }

    }

    private fun displayListInApp(title: String?, items: List<String>?) {
        val titleTextView: TextView = findViewById(R.id.titleTextView)
        val linearLayout: LinearLayout = findViewById(R.id.linearLayout)
        val serviceStatus: TextView = findViewById(R.id.serviceStatus)
        val overlayPermissionStatus: TextView = findViewById(R.id.overlayPermissionStatus)
        val batteryOptimizationStatus: TextView = findViewById(R.id.batteryOptimizationStatus)
        val testButton: Button = findViewById(R.id.testButton)
        if (items.isNullOrEmpty()) {
            titleTextView.visibility = View.GONE
            linearLayout.visibility = View.GONE
            serviceStatus.visibility = View.VISIBLE
            overlayPermissionStatus.visibility = View.VISIBLE
            batteryOptimizationStatus.visibility = View.VISIBLE
            testButton.visibility = View.VISIBLE
            return
        }

        titleTextView.text = title ?: "ירי רקטות וטילים"  // Set the title
        titleTextView.visibility = View.VISIBLE
        linearLayout.removeAllViews()  // Clear any existing views
        linearLayout.visibility = View.VISIBLE
        serviceStatus.visibility = View.GONE
        overlayPermissionStatus.visibility = View.GONE
        batteryOptimizationStatus.visibility = View.GONE
        testButton.visibility = View.GONE
        val sortedItems = items.sorted()

        // Measure titleTextView after setting text
        titleTextView.measure(0, 0)
        titleTextView.viewTreeObserver.addOnGlobalLayoutListener(object :
            ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                val totalTitleWidth = titleTextView.measuredWidth
                val numberOfColumns = (sortedItems.size + 14) / 15
                for (i in 0 until numberOfColumns) {
                    val column =
                        LinearLayout(this@MainActivity)  // Replace 'YourActivityName' with your actual Activity's name
                    column.orientation = LinearLayout.VERTICAL
                    column.layoutParams = LinearLayout.LayoutParams(
                        totalTitleWidth,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        if (i > 0) rightMargin = 5
                    }
                    linearLayout.addView(column)

                    val startIndex = i * 15
                    val endIndex = minOf(startIndex + 15, sortedItems.size)
                    for (j in startIndex until endIndex) {
                        val itemTextView =
                            TextView(this@MainActivity)  // Replace 'YourActivityName' with your actual Activity's name
                        itemTextView.text = sortedItems[j]
                        itemTextView.setTextColor(Color.WHITE)
                        itemTextView.setBackgroundResource(R.drawable.gradient_background)
                        itemTextView.textSize = 16f
                        itemTextView.setTypeface(null, Typeface.BOLD)
                        itemTextView.setPadding(10, 2, 10, 2)
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
        if (!listDisplayed || listDisplayDuration > 20000) {
            listDisplayed = true
            listDisplayDuration = 0L


            // Make it disappear after 20 seconds
            Handler(Looper.getMainLooper()).postDelayed({
                linearLayout.removeAllViews()
                titleTextView.text = ""
                titleTextView.visibility = View.GONE
                linearLayout.visibility = View.GONE
                serviceStatus.visibility = View.VISIBLE
                overlayPermissionStatus.visibility = View.VISIBLE
                batteryOptimizationStatus.visibility = View.VISIBLE
                testButton.visibility = View.VISIBLE
                listDisplayed = false
            }, 20000L) // remove after 20 seconds
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        updateStatuses()
        val fromOverlayService = intent.getBooleanExtra("fromOverlayService", false)
        Log.d("MainActivity", "fromOverlayService: $fromOverlayService")
        if (fromOverlayService) {
            listDisplayDuration += 1000L
            val title = intent.getStringExtra("title")
            val items = intent.getStringArrayExtra("items")?.toList()
            displayListInApp(title, items)
        }
    }

    private fun updateStatuses() {
        findViewById<TextView>(R.id.serviceStatus).text =
            if (isServiceRunning(OverlayService::class.java))
                "מצב השירות: פעיל"
            else
                "מצב השירות: לא פעיל"

        findViewById<TextView>(R.id.overlayPermissionStatus).apply {
            text =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this@MainActivity))
                    "הרשאה להופיע מעל אפליקציות: לא מופעלת"
                else
                    "הרשאה להופיע מעל אפליקציות: מופעלת"
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val isIgnoringBatteryOptimizations =
            powerManager.isIgnoringBatteryOptimizations(packageName)

        findViewById<TextView>(R.id.batteryOptimizationStatus).apply {
            text = if (isIgnoringBatteryOptimizations)
                "אופטימיזציה של צריכת אנרגיה: לא מופעלת"
            else
                "אופטימיזציה של צריכת אנרגיה: מופעלת"

        }
    }

    override fun onPause() {
        super.onPause()
        if (isServiceBound) {
            unbindService(serviceConnection)
            isServiceBound = false
        }
    }

    private fun checkOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            AlertDialog.Builder(this)
                .setTitle("הרשאה להופיע מעל חלונות אחרים")
                .setMessage(
                    "בכדי להציג התראות, האפליקציה דורשת הרשאה להופיע מעל חלונות אחרים. אנא עבור להגדרות המכשיר תחת\n" +
                            "'אפליקציות' -> 'גישה מיוחדת לאפליקציה' -> 'תצוגה מעל אפליקציות אחרות'\n" +
                            "ואשר את ההרשאה.\n" +
                            "לאחר מכן, הפעל את האפליקציה מחדש."
                )
                .setPositiveButton("אוקי") { dialog, _ -> dialog.dismiss() }
                .show()
        } else {
            startOverlayService()
        }
    }

    private fun promptForBatteryOptimizationsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                AlertDialog.Builder(this)
                    .setTitle("הרשאה לאופטימיזציות סוללה")
                    .setMessage(
                        "בכדי לקבל התראות בזמן אמת, האפליקציה דורשת הרשאה להתעלם מאופטימיזציות סוללה. אנא עבור להגדרות המכשיר תחת\n" +
                                "'אפליקציות' -> 'גישה מיוחדת לאפליקציה' -> 'אופטימיזציה של צריכת אנרגיה'\n" +
                                "וכבה את האפשרות.\nלאחר מכן, הפעל את האפליקציה מחדש."
                    )
                    .setPositiveButton("אוקי") { dialog, _ -> dialog.dismiss() }
                    .show()
            }
        }
    }


    private fun startOverlayService() {
        val serviceIntent = Intent(this, OverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun displayStatus() {
        val serviceStatus = if (isServiceBound) "השירות פעיל" else "השירות לא פעיל"
        val overlayStatus =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this))
                "הרשאה להופיע מעל חלונות אחרים ניתנה"
            else
                "הרשאה להופיע מעל חלונות אחרים לא ניתנה"

        Toast.makeText(this, "$serviceStatus\n$overlayStatus", Toast.LENGTH_LONG).show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == overlayPermissionRequestCode) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this)) {
                startOverlayService()
            }
        }
    }


    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }

}
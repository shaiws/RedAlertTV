package com.shaiws.redalert

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.res.Configuration
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
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.LinearLayout
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.FragmentActivity
import com.google.android.material.tabs.TabLayout
import java.util.Locale


class MainActivity : FragmentActivity() {

    private var isServiceBound = false
    private val overlayPermissionRequestCode = 0

    private var listDisplayed = false
    private var listDisplayDuration = 0L

    private lateinit var overlayPermissionLauncher: ActivityResultLauncher<Intent>

    private lateinit var tabLayout: TabLayout
    private lateinit var drawerLayout: androidx.drawerlayout.widget.DrawerLayout
    private lateinit var navView: LinearLayout


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

        initializeOverlayPermissionLauncher()
        setupTabMenu()
        handleIncomingIntent()
    }

    private fun initializeOverlayPermissionLauncher() {
        overlayPermissionLauncher =
            registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
                // Check if the overlay permission has been granted
                if (Settings.canDrawOverlays(this)) {
                    startOverlayService()
                }
            }
    }

    private fun setupTabMenu() {
        tabLayout = findViewById(R.id.tabLayout)
        drawerLayout = findViewById(R.id.drawer_layout)
        navView = findViewById(R.id.nav_view)

        val savedLanguage = getSavedLanguage()
        setLocale(this, savedLanguage)

        val languageRadioGroup: RadioGroup = findViewById(R.id.languageRadioGroup)
        // Set the saved language as checked without triggering setOnCheckedChangeListener
        val radioId = when (savedLanguage) {
            "he" -> R.id.radioHebrew
            "en" -> R.id.radioEnglish
            "ru" -> R.id.radioRussian
            "ar" -> R.id.radioArabic
            else -> R.id.radioHebrew // Default
        }
        languageRadioGroup.check(radioId)

        languageRadioGroup.setOnCheckedChangeListener { _, checkedId ->
            val selectedLanguage = when (checkedId) {
                R.id.radioHebrew -> "he"
                R.id.radioEnglish -> "en"
                R.id.radioRussian -> "ru"
                R.id.radioArabic -> "ar"
                else -> "he" // Default
            }

            // Only set locale and recreate if the language has changed
            if (savedLanguage != selectedLanguage) {
                setLocale(this, selectedLanguage)
                saveLanguage(selectedLanguage)
                this.recreate()
            }
        }

        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                when (tab.position) {
                    1 -> {
                        if (isOverlayPermissionRequired()) {
                            showOverlayPermissionDialog()
                            displayListInApp(
                                getString(R.string.thisIsATest),
                                listOf(
                                    getString(R.string.test1),
                                    getString(R.string.test2),
                                    getString(R.string.test3),
                                    getString(R.string.bestIsToActivePer)
                                )
                            )
                        } else {
                            startDummyOverlayService()
                        }
                    }

                    2 -> {
                        drawerLayout.openDrawer(navView)
                    }
                }
            }

            override fun onTabUnselected(tab: TabLayout.Tab) {}

            override fun onTabReselected(tab: TabLayout.Tab) {}
        })
        tabLayout.selectTab(tabLayout.getTabAt(0))
        tabLayout.onFocusChangeListener =
            View.OnFocusChangeListener { v: View?, hasFocus: Boolean ->
                if (hasFocus) {
                    val focusedTab = tabLayout.getTabAt(0)
                    focusedTab?.select()
                }
            }
        updateTabTitles()


    }

    private fun updateTabTitles() {
        tabLayout.getTabAt(0)?.text = getString(R.string.statusTab)
        tabLayout.getTabAt(1)?.text = getString(R.string.testTab)
        tabLayout.getTabAt(2)?.text = getString(R.string.langTab)
    }

    override fun onBackPressed() {
        if (drawerLayout.isDrawerOpen(navView)) {
            drawerLayout.closeDrawer(navView)
        } else {
            super.onBackPressed()
        }
    }

    private fun showOverlayPermissionDialog() {
        AlertDialog.Builder(this)
            .setTitle(getString(R.string.permissionTitle))
            .setMessage(getString(R.string.permissionMessage))
            .setPositiveButton(getString(R.string.ok)) { dialog, _ ->
                dialog.dismiss()
                try {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                    } else {
                        Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS)
                    }
                    overlayPermissionLauncher.launch(intent)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error requesting overlay permission: ${e.message}")
                }
            }
            .show()
    }

    private fun handleIncomingIntent() {
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

    private fun isOverlayPermissionRequired(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)
    }

    private fun startDummyOverlayService() {
        val intent = Intent(this, OverlayService::class.java)
        intent.action = "ACTION_DISPLAY_DUMMY"
        startService(intent)
    }

    private fun checkOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            AlertDialog.Builder(this)
                .setTitle(resources.getString(R.string.permissionTitle))
                .setMessage(
                    resources.getString(R.string.permissionMessage)
                )
                .setPositiveButton(resources.getString(R.string.ok)) { dialog, _ ->
                    dialog.dismiss()
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            // For Android Oreo (8.0, API 26) and above
                            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                        } else {
                            // Fallback for earlier versions
                            Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS)
                        }
                        overlayPermissionLauncher.launch(intent)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error: ${e.message}")
                    }
                }
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
                    .setTitle(getString(R.string.batteryTitle))
                    .setMessage(
                        getString(R.string.batteryMessage)
                    )
                    .setPositiveButton(resources.getString(R.string.ok)) { dialog, _ ->
                        dialog.dismiss()
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Error: ${e.message}")
                        }
                    }
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

    private fun displayListInApp(title: String?, items: List<String>?) {
        val titleTextView: TextView = findViewById(R.id.titleTextView)
        val linearLayout: LinearLayout = findViewById(R.id.linearLayout)
        val serviceStatus: TextView = findViewById(R.id.serviceStatus)
        val overlayPermissionStatus: TextView = findViewById(R.id.overlayPermissionStatus)
        val batteryOptimizationStatus: TextView = findViewById(R.id.batteryOptimizationStatus)
        if (items.isNullOrEmpty()) {
            titleTextView.visibility = View.GONE
            linearLayout.visibility = View.GONE
            serviceStatus.visibility = View.VISIBLE
            overlayPermissionStatus.visibility = View.VISIBLE
            batteryOptimizationStatus.visibility = View.VISIBLE
            return
        }

        titleTextView.text = title ?: getString(R.string.defTitle)  // Set the title
        titleTextView.visibility = View.VISIBLE
        linearLayout.removeAllViews()  // Clear any existing views
        linearLayout.visibility = View.VISIBLE
        serviceStatus.visibility = View.GONE
        overlayPermissionStatus.visibility = View.GONE
        batteryOptimizationStatus.visibility = View.GONE
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
                        LinearLayout(this@MainActivity)
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
                            TextView(this@MainActivity)
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
                getString(R.string.activeService)
            else
                getString(R.string.deactiveService)

        findViewById<TextView>(R.id.overlayPermissionStatus).apply {
            text =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this@MainActivity))
                    context.getString(R.string.deniedPermissions)
                else
                    context.getString(R.string.grantedPermissions)
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val isIgnoringBatteryOptimizations =
            powerManager.isIgnoringBatteryOptimizations(packageName)

        findViewById<TextView>(R.id.batteryOptimizationStatus).apply {
            text = if (isIgnoringBatteryOptimizations)
                context.getString(R.string.deactiveBattery)
            else
                context.getString(R.string.activeBattery)

        }
    }

    override fun onPause() {
        super.onPause()
        if (isServiceBound) {
            unbindService(serviceConnection)
            isServiceBound = false
        }
    }


    private fun displayStatus() {
        val serviceStatus =
            if (isServiceBound) getString(R.string.serviceActive) else getString(R.string.serviceDeactive)
        val overlayStatus =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this))
                getString(R.string.overlayGranted)
            else
                getString(R.string.overlayDenied)

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


    private fun setLocale(context: Context, langCode: String) {
        val locale = Locale(langCode)
        Locale.setDefault(locale)

        val res = context.resources
        val config = Configuration(res.configuration)
        config.setLocale(locale)

        res.updateConfiguration(config, res.displayMetrics)

        // Also change the locale in the application context
        val appRes = context.applicationContext.resources
        val appConfig = Configuration(appRes.configuration)
        appConfig.setLocale(locale)

        appRes.updateConfiguration(appConfig, appRes.displayMetrics)

    }

    private fun saveLanguage(language: String) {
        val preferences = getSharedPreferences("settings", Context.MODE_PRIVATE)
        val editor = preferences.edit()
        editor.putString("language", language)
        editor.apply()
    }

    private fun getSavedLanguage(): String {
        val preferences = getSharedPreferences("settings", Context.MODE_PRIVATE)
        return preferences.getString("language", "en") ?: "en" // Default to English
    }


}
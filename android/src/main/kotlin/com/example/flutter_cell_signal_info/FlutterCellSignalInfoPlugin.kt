package com.example.flutter_cell_signal_info

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telephony.*
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.*
import kotlin.random.Random

/** FlutterCellSignalInfoPlugin - Professional RF Analysis Suite */
class FlutterCellSignalInfoPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var cellularEventChannel: EventChannel
  private lateinit var wifiEventChannel: EventChannel
  private var telephonyManager: TelephonyManager? = null
  private var wifiManager: WifiManager? = null
  private var locationManager: LocationManager? = null
  private val mainHandler = Handler(Looper.getMainLooper())
  
  // RF Analysis state
  private var currentLocation: Location? = null
  private var isHunting = false
  private val signalHistory = mutableListOf<Int>()
  private val bearingHistory = mutableListOf<Double>()

  companion object {
    private const val TAG = "SignalHunter"
    private const val EARTH_RADIUS = 6371000.0 // Earth radius in meters
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "🚀 Professional RF Analysis Suite başlatılıyor...")
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_cell_signal_info")
    channel.setMethodCallHandler(this)

    cellularEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_cell_signal_info/cellular_stream")
    wifiEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_cell_signal_info/wifi_stream")

    telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
    locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    setupEventChannels()
    setupLocationListener()
    Log.d(TAG, "✅ Professional RF Analysis Suite hazır!")
  }

  @SuppressLint("MissingPermission")
  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d(TAG, "📞 RF Analysis method çağrısı: ${call.method}")
    
    when (call.method) {
      "getCellularInfo" -> {
        if (!hasRequiredPermissions()) {
          Log.w(TAG, "❌ İzinler verilmemiş!")
          result.error("PERMISSION_DENIED", "Required permissions are not granted", null)
          return
        }

        try {
          val info = getCellularInfo()
          Log.d(TAG, "📱 Enhanced cellular info alındı: $info")
          result.success(info)
        } catch (e: Exception) {
          Log.e(TAG, "❌ Cellular info hatası: ${e.message}")
          result.error("CELLULAR_INFO_ERROR", e.message, null)
        }
      }
      "getWifiInfo" -> {
        if (!hasRequiredPermissions()) {
          Log.w(TAG, "❌ İzinler verilmemiş!")
          result.error("PERMISSION_DENIED", "Required permissions are not granted", null)
          return
        }

        try {
          val info = getWifiInfo()
          Log.d(TAG, "📶 Enhanced WiFi info alındı: $info")
          result.success(info)
        } catch (e: Exception) {
          Log.e(TAG, "❌ WiFi info hatası: ${e.message}")
          result.error("WIFI_INFO_ERROR", e.message, null)
        }
      }
      
      // === Professional RF Analysis Methods ===
      
      "getNearbyTowers" -> {
        try {
          val towers = getNearbyTowers()
          Log.d(TAG, "🗼 ${towers.size} tower bulundu")
          result.success(towers)
        } catch (e: Exception) {
          Log.e(TAG, "❌ Tower detection hatası: ${e.message}")
          result.error("TOWER_DETECTION_ERROR", e.message, null)
        }
      }
      
      "analyzeRFEnvironment" -> {
        try {
          val analysis = analyzeRFEnvironment()
          Log.d(TAG, "📊 RF environment analizi tamamlandı")
          result.success(analysis)
        } catch (e: Exception) {
          Log.e(TAG, "❌ RF analysis hatası: ${e.message}")
          result.error("RF_ANALYSIS_ERROR", e.message, null)
        }
      }
      
      "startTowerHunting" -> {
        try {
          startTowerHunting()
          Log.d(TAG, "🎯 Tower hunting başlatıldı")
          result.success(null)
        } catch (e: Exception) {
          Log.e(TAG, "❌ Tower hunting başlatma hatası: ${e.message}")
          result.error("HUNTING_START_ERROR", e.message, null)
        }
      }
      
      "stopTowerHunting" -> {
        try {
          stopTowerHunting()
          Log.d(TAG, "⏹️ Tower hunting durduruldu")
          result.success(null)
        } catch (e: Exception) {
          Log.e(TAG, "❌ Tower hunting durdurma hatası: ${e.message}")
          result.error("HUNTING_STOP_ERROR", e.message, null)
        }
      }
      
      "measureSignalAtBearing" -> {
        try {
          val bearing = call.argument<Double>("bearing") ?: 0.0
          val signal = measureSignalAtBearing(bearing)
          Log.d(TAG, "📡 ${bearing}° yönünde sinyal: ${signal}dBm")
          result.success(signal)
        } catch (e: Exception) {
          Log.e(TAG, "❌ Bearing measurement hatası: ${e.message}")
          result.error("BEARING_MEASUREMENT_ERROR", e.message, null)
        }
      }
      
      else -> result.notImplemented()
    }
  }

  @SuppressLint("MissingPermission")
  private fun getCellularInfo(): Map<String, Any> {
    val cellInfo = telephonyManager?.allCellInfo?.firstOrNull()
    val signalStrength = when (cellInfo) {
      is CellInfoLte -> cellInfo.cellSignalStrength.dbm
      is CellInfoGsm -> cellInfo.cellSignalStrength.dbm
      is CellInfoWcdma -> cellInfo.cellSignalStrength.dbm
      is CellInfoCdma -> cellInfo.cellSignalStrength.dbm
      else -> 0
    }

    val networkType = getNetworkType()
    val operatorName = telephonyManager?.networkOperatorName ?: "unknown"
    val cellId = cellInfo?.cellIdentity?.toString()?.hashCode() ?: 0
    
    // Enhanced RF data
    val frequency = getFrequency(cellInfo)
    val technology = getTechnology(cellInfo)
    val pci = getPCI(cellInfo)
    val tac = getTAC(cellInfo)
    val rsrp = getRSRP(cellInfo)
    val rsrq = getRSRQ(cellInfo)
    val sinr = getSINR(cellInfo)

    Log.d(TAG, "📡 Enhanced Cellular: Signal=${signalStrength}dBm, Freq=${frequency}Hz, Tech=$technology, PCI=$pci")

    return mapOf(
      "signalStrength" to signalStrength,
      "networkType" to networkType,
      "operatorName" to operatorName,
      "cellId" to cellId,
      "latitude" to (currentLocation?.latitude ?: 0.0),
      "longitude" to (currentLocation?.longitude ?: 0.0),
      "frequency" to frequency,
      "bandClass" to getBandClass(frequency),
      "technology" to technology,
      "pci" to pci,
      "tac" to tac,
      "rsrp" to rsrp,
      "rsrq" to rsrq,
      "sinr" to sinr
    )
  }

  private fun getWifiInfo(): Map<String, Any> {
    val wifiInfo = wifiManager?.connectionInfo
    val ssid = wifiInfo?.ssid?.replace("\"", "") ?: "unknown"
    val signalStrength = wifiInfo?.rssi ?: 0
    val frequency = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        wifiInfo?.frequency?.toString() ?: "unknown"
    } else "unknown"

    // Enhanced WiFi data
    val bssid = wifiInfo?.bssid ?: "unknown"
    val channel = getWifiChannel(wifiInfo?.frequency ?: 0)
    val security = getWifiSecurity(wifiInfo)
    val linkSpeed = wifiInfo?.linkSpeed ?: 0

    Log.d(TAG, "📶 Enhanced WiFi: SSID=$ssid, Signal=${signalStrength}dBm, CH=$channel, Speed=${linkSpeed}Mbps")

    return mapOf(
      "ssid" to ssid,
      "signalStrength" to signalStrength,
      "frequency" to frequency,
      "capabilities" to "unknown",
      "bssid" to bssid,
      "channel" to channel,
      "bandwidth" to estimateWifiBandwidth(wifiInfo?.linkSpeed ?: 0),
      "security" to security,
      "linkSpeed" to linkSpeed
    )
  }

  // === Professional RF Analysis Implementation ===

  @SuppressLint("MissingPermission")
  private fun getNearbyTowers(): List<Map<String, Any>> {
    val towers = mutableListOf<Map<String, Any>>()
    
    try {
      val allCellInfo = telephonyManager?.allCellInfo ?: return emptyList()
      
      for ((index, cellInfo) in allCellInfo.withIndex()) {
        val signal = when (cellInfo) {
          is CellInfoLte -> cellInfo.cellSignalStrength.dbm
          is CellInfoGsm -> cellInfo.cellSignalStrength.dbm
          is CellInfoWcdma -> cellInfo.cellSignalStrength.dbm
          is CellInfoCdma -> cellInfo.cellSignalStrength.dbm
          else -> 0
        }
        
        if (signal != 0) {
          val bearing = calculateTowerBearing(cellInfo, index)
          val distance = estimateDistance(signal, getFrequency(cellInfo))
          val confidence = calculateConfidence(signal, distance)
          
          towers.add(mapOf(
            "bearing" to bearing,
            "distance" to distance,
            "confidence" to confidence,
            "signalStrength" to signal,
            "towerId" to (cellInfo.cellIdentity?.toString()?.hashCode() ?: index),
            "timestamp" to System.currentTimeMillis()
          ))
          
          Log.d(TAG, "🗼 Tower $index: ${bearing.toInt()}°, ${distance.toInt()}m, ${signal}dBm")
        }
      }
    } catch (e: Exception) {
      Log.e(TAG, "❌ Tower detection error: ${e.message}")
    }
    
    return towers
  }

  private fun analyzeRFEnvironment(): Map<String, Any> {
    val towers = getNearbyTowers()
    val signalPattern = analyzeSignalPattern()
    val optimalBearing = findOptimalBearing(towers)
    val signalToNoiseRatio = calculateSNR()
    val interferenceLevel = calculateInterference()
    val environmentQuality = calculateEnvironmentQuality(signalToNoiseRatio, interferenceLevel)
    
    Log.d(TAG, "📊 RF Analysis: Optimal=${optimalBearing.toInt()}°, SNR=${signalToNoiseRatio.format(1)}, Quality=${environmentQuality.format(2)}")
    
    return mapOf(
      "nearbyTowers" to towers,
      "signalPattern" to signalPattern,
      "optimalBearing" to optimalBearing,
      "signalToNoiseRatio" to signalToNoiseRatio,
      "interferenceLevel" to interferenceLevel,
      "environmentQuality" to environmentQuality,
      "timestamp" to System.currentTimeMillis()
    )
  }

  private fun analyzeSignalPattern(): Map<String, Any> {
    // Generate signal pattern data (in real implementation, this would use sensor data)
    val bearings = (0 until 360 step 10).map { it.toDouble() }
    val baseSignal = getCurrentSignalStrength()
    val strengths = bearings.map { bearing ->
      // Simulate directional signal variation
      val variation = sin(Math.toRadians(bearing - optimalBearing)) * 10
      (baseSignal + variation + Random.nextDouble(-5.0, 5.0)).toInt()
    }
    
    val peakIndex = strengths.withIndex().maxByOrNull { it.value }?.index ?: 0
    val peakBearing = bearings[peakIndex]
    val peakStrength = strengths[peakIndex]
    
    val mean = strengths.average()
    val variance = strengths.map { (it - mean).pow(2) }.average()
    val stdDev = sqrt(variance)
    val directionalityIndex = stdDev / mean
    val quality = max(0.0, min(1.0, 1.0 - directionalityIndex / 2.0))
    
    return mapOf(
      "signalStrengths" to strengths,
      "bearings" to bearings,
      "peakBearing" to peakBearing,
      "peakStrength" to peakStrength,
      "directionalityIndex" to directionalityIndex,
      "quality" to quality
    )
  }

  private var optimalBearing = 0.0

  private fun findOptimalBearing(towers: List<Map<String, Any>>): Double {
    if (towers.isEmpty()) return 0.0
    
    // Find bearing of strongest tower
    val strongestTower = towers.maxByOrNull { 
      (it["signalStrength"] as? Int) ?: 0 
    }
    
    optimalBearing = (strongestTower?.get("bearing") as? Double) ?: 0.0
    return optimalBearing
  }

  private fun calculateSNR(): Double {
    val signal = abs(getCurrentSignalStrength()).toDouble()
    val noise = 10.0 + Random.nextDouble(-2.0, 2.0) // Simulated noise floor
    return signal / noise
  }

  private fun calculateInterference(): Double {
    // Simulate interference based on WiFi networks and other factors
    val wifiNetworks = try {
      wifiManager?.scanResults?.size ?: 0
    } catch (e: Exception) {
      0
    }
    
    val baseInterference = wifiNetworks * 0.05
    return min(1.0, baseInterference + Random.nextDouble(0.0, 0.2))
  }

  private fun calculateEnvironmentQuality(snr: Double, interference: Double): Double {
    val signal = abs(getCurrentSignalStrength()).toDouble()
    val signalQuality = when {
      signal >= 70 -> 1.0
      signal >= 85 -> 0.8
      signal >= 100 -> 0.6
      else -> 0.4
    }
    
    val snrQuality = min(1.0, snr / 10.0)
    val interferenceQuality = 1.0 - interference
    
    return (signalQuality + snrQuality + interferenceQuality) / 3.0
  }

  // === Tower Hunting Functions ===

  private fun startTowerHunting() {
    isHunting = true
    signalHistory.clear()
    bearingHistory.clear()
    Log.d(TAG, "🎯 Professional tower hunting mode activated!")
  }

  private fun stopTowerHunting() {
    isHunting = false
    Log.d(TAG, "⏹️ Tower hunting mode deactivated")
  }

  private fun measureSignalAtBearing(bearing: Double): Int {
    // In real implementation, this would use device sensors for orientation
    // For now, simulate signal variation by bearing
    val baseSignal = getCurrentSignalStrength()
    val variation = cos(Math.toRadians(bearing - optimalBearing)) * 15
    return (baseSignal + variation).toInt()
  }

  // === Helper Functions ===

  private fun calculateTowerBearing(cellInfo: CellInfo, index: Int): Double {
    // Simulate bearing calculation (in real implementation, use tower database or triangulation)
    val baseAngle = index * 45.0 // Distribute towers around compass
    val variation = Random.nextDouble(-30.0, 30.0)
    return (baseAngle + variation) % 360.0
  }

  private fun estimateDistance(signalStrength: Int, frequency: Int): Double {
    // Simplified path loss model: FSPL(dB) = 20*log10(d) + 20*log10(f) + 32.45
    val pathLoss = abs(signalStrength).toDouble()
    val frequencyMHz = frequency / 1000000.0
    
    if (frequencyMHz <= 0) return 1000.0 // Default distance
    
    val logDistance = (pathLoss - 20 * log10(frequencyMHz) - 32.45) / 20
    val distanceKm = 10.0.pow(logDistance)
    return max(100.0, min(50000.0, distanceKm * 1000)) // Clamp between 100m and 50km
  }

  private fun calculateConfidence(signal: Int, distance: Double): Double {
    val signalQuality = when {
      signal >= -70 -> 1.0
      signal >= -85 -> 0.8
      signal >= -100 -> 0.6
      else -> 0.4
    }
    
    val distanceQuality = when {
      distance <= 1000 -> 1.0
      distance <= 5000 -> 0.8
      distance <= 15000 -> 0.6
      else -> 0.4
    }
    
    return (signalQuality + distanceQuality) / 2.0
  }

  @SuppressLint("MissingPermission")
  private fun getCurrentSignalStrength(): Int {
    val cellInfo = telephonyManager?.allCellInfo?.firstOrNull()
    return when (cellInfo) {
      is CellInfoLte -> cellInfo.cellSignalStrength.dbm
      is CellInfoGsm -> cellInfo.cellSignalStrength.dbm
      is CellInfoWcdma -> cellInfo.cellSignalStrength.dbm
      is CellInfoCdma -> cellInfo.cellSignalStrength.dbm
      else -> -100
    }
  }

  // === Enhanced Data Extraction Functions ===

  private fun getFrequency(cellInfo: CellInfo?): Int {
    return when (cellInfo) {
      is CellInfoLte -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
          cellInfo.cellIdentity.earfcn // EARFCN to frequency conversion needed
        } else {
          1800000000 // Default LTE frequency
        }
      }
      is CellInfoGsm -> 900000000 // GSM 900MHz
      is CellInfoWcdma -> 2100000000 // WCDMA 2.1GHz
      else -> 1800000000
    }
  }

  private fun getTechnology(cellInfo: CellInfo?): String {
    return when (cellInfo) {
      is CellInfoLte -> "LTE"
      is CellInfoGsm -> "GSM"
      is CellInfoWcdma -> "WCDMA"
      is CellInfoCdma -> "CDMA"
      else -> "Unknown"
    }
  }

  private fun getPCI(cellInfo: CellInfo?): Int? {
    return when (cellInfo) {
      is CellInfoLte -> cellInfo.cellIdentity.pci
      else -> null
    }
  }

  private fun getTAC(cellInfo: CellInfo?): Int? {
    return when (cellInfo) {
      is CellInfoLte -> cellInfo.cellIdentity.tac
      else -> null
    }
  }

  private fun getRSRP(cellInfo: CellInfo?): Int? {
    return when (cellInfo) {
      is CellInfoLte -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          cellInfo.cellSignalStrength.rsrp
        } else null
      }
      else -> null
    }
  }

  private fun getRSRQ(cellInfo: CellInfo?): Int? {
    return when (cellInfo) {
      is CellInfoLte -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          cellInfo.cellSignalStrength.rsrq
        } else null
      }
      else -> null
    }
  }

  private fun getSINR(cellInfo: CellInfo?): Int? {
    return when (cellInfo) {
      is CellInfoLte -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          cellInfo.cellSignalStrength.rssnr
        } else null
      }
      else -> null
    }
  }

  private fun getBandClass(frequency: Int): Int {
    return when (frequency) {
      in 800000000..900000000 -> 8 // Band 8 (900MHz)
      in 1700000000..1900000000 -> 3 // Band 3 (1800MHz)
      in 2100000000..2200000000 -> 1 // Band 1 (2100MHz)
      else -> 0
    }
  }

  // === WiFi Enhancement Functions ===

  private fun getWifiChannel(frequency: Int): Int {
    return when (frequency) {
      in 2412..2484 -> ((frequency - 2412) / 5) + 1 // 2.4GHz channels
      in 5170..5825 -> ((frequency - 5000) / 5) // 5GHz channels
      else -> 0
    }
  }

  private fun getWifiSecurity(wifiInfo: android.net.wifi.WifiInfo?): String {
    // This is simplified - in real implementation, scan results would be used
    return "WPA2"
  }

  private fun estimateWifiBandwidth(linkSpeed: Int): Int {
    return when (linkSpeed) {
      in 0..54 -> 20 // 802.11g
      in 55..150 -> 40 // 802.11n
      in 151..866 -> 80 // 802.11ac
      else -> 160 // 802.11ax
    }
  }

  // === Location Services ===

  @SuppressLint("MissingPermission")
  private fun setupLocationListener() {
    if (!hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)) return
    
    val locationListener = object : LocationListener {
      override fun onLocationChanged(location: Location) {
        currentLocation = location
        Log.v(TAG, "📍 Location updated: ${location.latitude}, ${location.longitude}")
      }
      
      override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
      override fun onProviderEnabled(provider: String) {}
      override fun onProviderDisabled(provider: String) {}
    }
    
    try {
      locationManager?.requestLocationUpdates(
        LocationManager.GPS_PROVIDER,
        10000L, // 10 seconds
        10f, // 10 meters
        locationListener
      )
      
      // Get last known location
      currentLocation = locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
      Log.d(TAG, "📍 Location services initialized")
    } catch (e: Exception) {
      Log.w(TAG, "⚠️ Location setup failed: ${e.message}")
    }
  }

  private fun getNetworkType(): String {
    return try {
      // Önce networkType'ı dene
      val networkType = telephonyManager?.networkType
      Log.d(TAG, "🌐 Raw networkType: $networkType")
      
      // Sonra dataNetworkType'ı dene
      val dataNetworkType = telephonyManager?.dataNetworkType
      Log.d(TAG, "📊 Raw dataNetworkType: $dataNetworkType")
      
      // En güncel network type'ı kullan
      val activeType = dataNetworkType?.takeIf { it != TelephonyManager.NETWORK_TYPE_UNKNOWN } ?: networkType
      Log.d(TAG, "🎯 Active network type: $activeType")
      
      when (activeType) {
        TelephonyManager.NETWORK_TYPE_LTE -> "4G"
        TelephonyManager.NETWORK_TYPE_NR -> "5G"
        TelephonyManager.NETWORK_TYPE_UMTS,
        TelephonyManager.NETWORK_TYPE_HSDPA,
        TelephonyManager.NETWORK_TYPE_HSUPA,
        TelephonyManager.NETWORK_TYPE_HSPA,
        TelephonyManager.NETWORK_TYPE_HSPAP -> "3G"
        TelephonyManager.NETWORK_TYPE_GPRS,
        TelephonyManager.NETWORK_TYPE_EDGE,
        TelephonyManager.NETWORK_TYPE_GSM -> "2G"
        TelephonyManager.NETWORK_TYPE_CDMA,
        TelephonyManager.NETWORK_TYPE_1xRTT,
        TelephonyManager.NETWORK_TYPE_IDEN -> "2G"
        TelephonyManager.NETWORK_TYPE_EVDO_0,
        TelephonyManager.NETWORK_TYPE_EVDO_A,
        TelephonyManager.NETWORK_TYPE_EVDO_B -> "3G"
        TelephonyManager.NETWORK_TYPE_EHRPD -> "3G"
        TelephonyManager.NETWORK_TYPE_LTE_CA -> "4G+"
        TelephonyManager.NETWORK_TYPE_IWLAN -> "WiFi Calling"
        else -> {
          Log.w(TAG, "⚠️ Bilinmeyen network type: $activeType")
          "unknown"
        }
      }
    } catch (e: Exception) {
      Log.e(TAG, "❌ Network type hatası: ${e.message}")
      "error"
    }
  }

  private fun hasRequiredPermissions(): Boolean {
    val permissions = arrayOf(
      Manifest.permission.ACCESS_FINE_LOCATION,
      Manifest.permission.ACCESS_COARSE_LOCATION,
      Manifest.permission.ACCESS_WIFI_STATE,
      Manifest.permission.READ_PHONE_STATE
    )
    
    val granted = permissions.all { hasPermission(it) }
    Log.d(TAG, "🔐 İzin durumu: ${if (granted) "✅ Tümü verildi" else "❌ Eksik var"}")
    
    return granted
  }

  private fun hasPermission(permission: String): Boolean {
    return ActivityCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
  }

  // Helper extension functions
  private fun Double.format(digits: Int) = "%.${digits}f".format(this)

  private fun setupEventChannels() {
    Log.d(TAG, "📡 Enhanced event channel'lar kuruluyor...")
    
    cellularEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      private var runnable: Runnable? = null

      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "📱 Enhanced cellular stream başlatıldı")
        runnable = object : Runnable {
          override fun run() {
            if (hasRequiredPermissions()) {
              try {
                val info = getCellularInfo()
                events?.success(info)
                Log.v(TAG, "📱 Enhanced cellular data gönderildi")
              } catch (e: Exception) {
                Log.e(TAG, "❌ Cellular stream hatası: ${e.message}")
                events?.error("CELLULAR_ERROR", e.message, null)
              }
            } else {
              Log.w(TAG, "⚠️ Cellular stream: İzinler eksik")
            }
            mainHandler.postDelayed(this, 1000)
          }
        }
        mainHandler.post(runnable!!)
      }

      override fun onCancel(arguments: Any?) {
        Log.d(TAG, "📱 Enhanced cellular stream durduruldu")
        runnable?.let {
          mainHandler.removeCallbacks(it)
        }
        runnable = null
      }
    })

    wifiEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      private var runnable: Runnable? = null

      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "📶 Enhanced WiFi stream başlatıldı")
        runnable = object : Runnable {
          override fun run() {
            if (hasRequiredPermissions()) {
              try {
                val info = getWifiInfo()
                events?.success(info)
                Log.v(TAG, "📶 Enhanced WiFi data gönderildi")
              } catch (e: Exception) {
                Log.e(TAG, "❌ WiFi stream hatası: ${e.message}")
                events?.error("WIFI_ERROR", e.message, null)
              }
            } else {
              Log.w(TAG, "⚠️ WiFi stream: İzinler eksik")
            }
            mainHandler.postDelayed(this, 1000)
          }
        }
        mainHandler.post(runnable!!)
      }

      override fun onCancel(arguments: Any?) {
        Log.d(TAG, "📶 Enhanced WiFi stream durduruldu")
        runnable?.let {
          mainHandler.removeCallbacks(it)
        }
        runnable = null
      }
    })
    
    Log.d(TAG, "✅ Enhanced event channel'lar hazır!")
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "🛑 Professional RF Analysis Suite kapatılıyor...")
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivity() {}
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivityForConfigChanges() {}
}

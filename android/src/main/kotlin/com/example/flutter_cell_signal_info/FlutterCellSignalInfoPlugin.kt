package com.example.flutter_cell_signal_info

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.telephony.*
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterCellSignalInfoPlugin */
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

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_cell_signal_info")
    channel.setMethodCallHandler(this)

    cellularEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_cell_signal_info/cellular_stream")
    wifiEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_cell_signal_info/wifi_stream")

    telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager

    setupEventChannels()
  }

  @SuppressLint("MissingPermission")
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getCellularInfo" -> {
        if (!hasRequiredPermissions()) {
          result.error("PERMISSION_DENIED", "Required permissions are not granted", null)
          return
        }

        try {
          val info = getCellularInfo()
          result.success(info)
        } catch (e: Exception) {
          result.error("CELLULAR_INFO_ERROR", e.message, null)
        }
      }
      "getWifiInfo" -> {
        if (!hasRequiredPermissions()) {
          result.error("PERMISSION_DENIED", "Required permissions are not granted", null)
          return
        }

        try {
          val info = getWifiInfo()
          result.success(info)
        } catch (e: Exception) {
          result.error("WIFI_INFO_ERROR", e.message, null)
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

    return mapOf(
      "signalStrength" to signalStrength,
      "networkType" to getNetworkType(),
      "operatorName" to (telephonyManager?.networkOperatorName ?: "unknown"),
      "cellId" to (cellInfo?.cellIdentity?.toString()?.hashCode() ?: 0),
      "latitude" to 0.0, // Requires location permission and implementation
      "longitude" to 0.0
    )
  }

  private fun getWifiInfo(): Map<String, Any> {
    val wifiInfo = wifiManager?.connectionInfo
    return mapOf(
      "ssid" to (wifiInfo?.ssid?.replace("\"", "") ?: "unknown"),
      "signalStrength" to (wifiInfo?.rssi ?: 0),
      "frequency" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        wifiInfo?.frequency?.toString() ?: "unknown"
      } else "unknown"),
      "capabilities" to "unknown"
    )
  }

  private fun getNetworkType(): String {
    return when (telephonyManager?.dataNetworkType) {
      TelephonyManager.NETWORK_TYPE_LTE -> "4G"
      TelephonyManager.NETWORK_TYPE_NR -> "5G"
      TelephonyManager.NETWORK_TYPE_UMTS,
      TelephonyManager.NETWORK_TYPE_HSDPA,
      TelephonyManager.NETWORK_TYPE_HSPA -> "3G"
      TelephonyManager.NETWORK_TYPE_GPRS,
      TelephonyManager.NETWORK_TYPE_EDGE -> "2G"
      else -> "unknown"
    }
  }

  private fun hasRequiredPermissions(): Boolean {
    return hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) &&
      hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION) &&
      hasPermission(Manifest.permission.ACCESS_WIFI_STATE) &&
      hasPermission(Manifest.permission.READ_PHONE_STATE)
  }

  private fun hasPermission(permission: String): Boolean {
    return ActivityCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
  }

  private fun setupEventChannels() {
    cellularEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      private var timer: java.util.Timer? = null

      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        timer = java.util.Timer()
        timer?.scheduleAtFixedRate(object : java.util.TimerTask() {
          override fun run() {
            if (hasRequiredPermissions()) {
              events?.success(getCellularInfo())
            }
          }
        }, 0, 1000)
      }

      override fun onCancel(arguments: Any?) {
        timer?.cancel()
        timer = null
      }
    })

    wifiEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      private var timer: java.util.Timer? = null

      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        timer = java.util.Timer()
        timer?.scheduleAtFixedRate(object : java.util.TimerTask() {
          override fun run() {
            if (hasRequiredPermissions()) {
              events?.success(getWifiInfo())
            }
          }
        }, 0, 1000)
      }

      override fun onCancel(arguments: Any?) {
        timer?.cancel()
        timer = null
      }
    })
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivity() {}
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivityForConfigChanges() {}
}

package com.example.exemplo_quatro

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.NetworkInfo
import android.net.wifi.WpsInfo
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.Collections
import java.util.concurrent.Executors

class WifiDirectTransport(
    private val activity: Activity,
    private val methodChannel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    private val manager =
        activity.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()
    private val peers = mutableMapOf<String, WifiP2pDevice>()
    private val sockets = Collections.synchronizedMap(mutableMapOf<String, Socket>())
    private val socketNames = Collections.synchronizedMap(mutableMapOf<String, String>())
    private val intentFilter = IntentFilter().apply {
        addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
    }

    private var wifiChannel: WifiP2pManager.Channel? = null
    private var receiverRegistered = false
    private var serverSocket: ServerSocket? = null
    private var serverRunning = false
    private var localName = "Aparelho"
    private var pendingPeerAddress: String? = null
    private var pendingPeerName: String? = null
    private var discovering = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    if (state != WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                        emitError("Wi-Fi Direct indisponivel neste aparelho.")
                    }
                }

                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> requestPeers()
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    val networkInfo = intent.networkInfoExtra()
                    if (networkInfo?.isConnected == true) {
                        requestConnectionInfo()
                    }
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> start(call, result)
            "discover" -> discover(result)
            "stopDiscovery" -> stopDiscovery(result)
            "connect" -> connect(call, result)
            "sendBytes" -> sendBytes(call, result)
            "stop" -> stop(result)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        stopInternal(removeGroup = false)
        executor.shutdownNow()
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val deviceName = call.argument<String>("deviceName")?.trim()
        if (!deviceName.isNullOrEmpty()) {
            localName = deviceName
        }

        if (manager == null) {
            result.error("wifi_direct_unavailable", "WifiP2pManager indisponivel.", null)
            return
        }

        if (wifiChannel == null) {
            wifiChannel = manager.initialize(activity.applicationContext, activity.mainLooper) {
                emitError("Canal Wi-Fi Direct desconectado.")
            }
        }

        if (!receiverRegistered) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(receiver, intentFilter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                activity.registerReceiver(receiver, intentFilter)
            }
            receiverRegistered = true
        }

        startServer()
        result.success(null)
    }

    @SuppressLint("MissingPermission")
    private fun discover(result: MethodChannel.Result) {
        val manager = manager
        val channel = wifiChannel
        if (manager == null || channel == null) {
            result.error("wifi_direct_not_started", "Inicie o Wi-Fi Direct antes da busca.", null)
            return
        }
        if (!hasWifiDirectPermission()) {
            result.error("wifi_direct_permission", "Permissao de Wi-Fi Direct ausente.", null)
            return
        }

        manager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                discovering = true
                emit("discoveryChanged", mapOf("discovering" to true))
                result.success(null)
            }

            override fun onFailure(reason: Int) {
                discovering = false
                emit("discoveryChanged", mapOf("discovering" to false))
                result.error(
                    "wifi_direct_discover_failed",
                    "Falha ao buscar Wi-Fi Direct: $reason",
                    null,
                )
            }
        })
    }

    @SuppressLint("MissingPermission")
    private fun stopDiscovery(result: MethodChannel.Result) {
        val manager = manager
        val channel = wifiChannel
        if (manager == null || channel == null) {
            result.success(null)
            return
        }

        manager.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                discovering = false
                emit("discoveryChanged", mapOf("discovering" to false))
                result.success(null)
            }

            override fun onFailure(reason: Int) {
                discovering = false
                emit("discoveryChanged", mapOf("discovering" to false))
                result.success(null)
            }
        })
    }

    @SuppressLint("MissingPermission")
    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        val deviceId = call.argument<String>("deviceId")
        val manager = manager
        val channel = wifiChannel
        if (deviceId.isNullOrEmpty() || manager == null || channel == null) {
            result.error("wifi_direct_invalid_peer", "Dispositivo Wi-Fi Direct invalido.", null)
            return
        }
        if (!hasWifiDirectPermission()) {
            result.error("wifi_direct_permission", "Permissao de Wi-Fi Direct ausente.", null)
            return
        }

        pendingPeerAddress = deviceId
        pendingPeerName = peers[deviceId]?.deviceName?.takeIf { it.isNotBlank() }
            ?: "Wi-Fi Direct"

        val config = WifiP2pConfig().apply {
            deviceAddress = deviceId
            wps.setup = WpsInfo.PBC
        }

        manager.connect(channel, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                result.success(null)
            }

            override fun onFailure(reason: Int) {
                pendingPeerAddress = null
                pendingPeerName = null
                result.error(
                    "wifi_direct_connect_failed",
                    "Falha ao conectar por Wi-Fi Direct: $reason",
                    null,
                )
            }
        })
    }

    private fun sendBytes(call: MethodCall, result: MethodChannel.Result) {
        val deviceId = call.argument<String>("deviceId")
        val data = call.argument<ByteArray>("data")
        if (deviceId.isNullOrEmpty() || data == null) {
            result.error("wifi_direct_invalid_payload", "Mensagem Wi-Fi Direct invalida.", null)
            return
        }

        val socket = sockets[deviceId]
        if (socket == null || socket.isClosed) {
            result.error("wifi_direct_not_connected", "Dispositivo Wi-Fi Direct desconectado.", null)
            return
        }

        executor.execute {
            try {
                synchronized(socket) {
                    val output = DataOutputStream(socket.getOutputStream())
                    output.writeInt(data.size)
                    output.write(data)
                    output.flush()
                }
                mainHandler.post { result.success(null) }
            } catch (error: Exception) {
                closeConnection(deviceId)
                mainHandler.post {
                    result.error(
                        "wifi_direct_send_failed",
                        "Falha ao enviar por Wi-Fi Direct: ${error.message}",
                        null,
                    )
                }
            }
        }
    }

    private fun stop(result: MethodChannel.Result) {
        stopInternal(removeGroup = true)
        result.success(null)
    }

    @SuppressLint("MissingPermission")
    private fun requestPeers() {
        val manager = manager
        val channel = wifiChannel
        if (manager == null || channel == null || !hasWifiDirectPermission()) return

        manager.requestPeers(channel) { list: WifiP2pDeviceList ->
            peers.clear()
            val devices = list.deviceList.mapNotNull { device ->
                val address = device.deviceAddress ?: return@mapNotNull null
                peers[address] = device
                mapOf(
                    "id" to address,
                    "name" to (device.deviceName?.takeIf { it.isNotBlank() } ?: address),
                )
            }
            emit("peersChanged", devices)
        }
    }

    @SuppressLint("MissingPermission")
    private fun requestConnectionInfo() {
        val manager = manager
        val channel = wifiChannel
        if (manager == null || channel == null || !hasWifiDirectPermission()) return

        manager.requestConnectionInfo(channel) { info: WifiP2pInfo ->
            if (!info.groupFormed) return@requestConnectionInfo
            startServer()
            if (!info.isGroupOwner && info.groupOwnerAddress != null) {
                connectToGroupOwner(info.groupOwnerAddress.hostAddress)
            }
        }
    }

    private fun startServer() {
        if (serverRunning) return
        serverRunning = true

        executor.execute {
            try {
                val server = ServerSocket(PORT)
                serverSocket = server
                while (serverRunning) {
                    val socket = server.accept()
                    val host = socket.inetAddress.hostAddress ?: socket.remoteSocketAddress.toString()
                    val id = "ip:$host"
                    val name = "Wi-Fi Direct $host"
                    registerSocket(id, name, socket)
                }
            } catch (_: Exception) {
                if (serverRunning) {
                    emitError("Servidor Wi-Fi Direct encerrado.")
                }
            } finally {
                serverRunning = false
            }
        }
    }

    private fun connectToGroupOwner(host: String?) {
        if (host.isNullOrEmpty()) return

        executor.execute {
            try {
                val socket = Socket()
                socket.bind(null)
                socket.connect(InetSocketAddress(host, PORT), SOCKET_TIMEOUT_MS)
                val id = pendingPeerAddress ?: "ip:$host"
                val name = pendingPeerName ?: "Wi-Fi Direct $host"
                registerSocket(id, name, socket)
            } catch (error: Exception) {
                emitError("Falha no socket Wi-Fi Direct: ${error.message}")
            }
        }
    }

    private fun registerSocket(id: String, name: String, socket: Socket) {
        sockets.remove(id)?.close()
        sockets[id] = socket
        socketNames[id] = name
        emit("connected", mapOf("id" to id, "name" to name))

        executor.execute {
            try {
                val input = DataInputStream(BufferedInputStream(socket.getInputStream()))
                while (!socket.isClosed) {
                    val length = input.readInt()
                    if (length <= 0 || length > MAX_PACKET_BYTES) {
                        throw IllegalArgumentException("Pacote Wi-Fi Direct invalido.")
                    }
                    val data = ByteArray(length)
                    input.readFully(data)
                    emit(
                        "messageReceived",
                        mapOf("id" to id, "name" to name, "data" to data),
                    )
                }
            } catch (_: EOFException) {
                closeConnection(id)
            } catch (_: Exception) {
                closeConnection(id)
            }
        }
    }

    private fun closeConnection(id: String) {
        sockets.remove(id)?.close()
        socketNames.remove(id)
        emit("disconnected", mapOf("id" to id))
    }

    private fun stopInternal(removeGroup: Boolean) {
        if (discovering) {
            val manager = manager
            val channel = wifiChannel
            if (manager != null && channel != null) {
                try {
                    manager.stopPeerDiscovery(channel, null)
                } catch (_: Exception) {
                }
            }
        }
        discovering = false
        emit("discoveryChanged", mapOf("discovering" to false))

        serverRunning = false
        serverSocket?.close()
        serverSocket = null

        for (id in sockets.keys.toList()) {
            closeConnection(id)
        }
        peers.clear()
        emit("peersChanged", emptyList<Map<String, String>>())

        if (receiverRegistered) {
            try {
                activity.unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
            receiverRegistered = false
        }

        if (removeGroup) {
            val manager = manager
            val channel = wifiChannel
            if (manager != null && channel != null) {
                try {
                    manager.removeGroup(channel, null)
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun hasWifiDirectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        val locationGranted =
            activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return locationGranted
        }

        val nearbyWifiGranted =
            activity.checkSelfPermission(Manifest.permission.NEARBY_WIFI_DEVICES) ==
                PackageManager.PERMISSION_GRANTED
        return locationGranted || nearbyWifiGranted
    }

    private fun emit(method: String, arguments: Any?) {
        mainHandler.post {
            methodChannel.invokeMethod(method, arguments)
        }
    }

    private fun emitError(message: String) {
        emit("error", mapOf("message" to message))
    }

    @Suppress("DEPRECATION")
    private fun Intent.networkInfoExtra(): NetworkInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO, NetworkInfo::class.java)
        } else {
            getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO)
        }
    }

    companion object {
        private const val PORT = 8988
        private const val SOCKET_TIMEOUT_MS = 8500
        private const val MAX_PACKET_BYTES = 1024 * 1024
    }
}

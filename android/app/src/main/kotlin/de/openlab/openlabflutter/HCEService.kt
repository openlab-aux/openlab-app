package de.openlab.openlabflutter
import android.content.Intent
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

class HCEService : HostApduService() {
    var aid = byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    var hello =
        byteArrayOf(0, 0xA4.toByte(), 4, 0, 0xA0.toByte(), 0, 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte())
    var pollAccessToken =
        byteArrayOf(0, 0xA4.toByte(), 4, 0, 0xA0.toByte(), 0, 0xAA.toByte(), 0xAA.toByte(), 0xAA.toByte(), 0xAA.toByte(), 0xAA.toByte())

    var intent: Intent? = null

    public fun byteArrayToString(array: ByteArray): String {
        var str = "["
        for (i in 0..array.size - 2)
            str += " ${array[i].toUByte().toString(16)},"
        str += " ${array[array.size - 1].toUByte().toString(16)} ]"

        return str
    }

    override fun processCommandApdu(
        commandApdu: ByteArray?,
        extras: Bundle?,
    ): ByteArray {
        if (commandApdu != null) {
            Log.i("HCE", "APDU Command ${byteArrayToString(commandApdu)}")
            Log.i("HCE", "hello ${byteArrayToString(hello)}")
            Log.i("HCE", "pollAccessToken ${byteArrayToString(pollAccessToken)}")
            if (commandApdu contentEquals hello) {
                intent =
                    Intent(this, MainActivity::class.java)
                        .apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            putExtra("hce", 0)
                        }

                startActivity(intent)
                return byteArrayOf(0x90.toByte(), 0x00)
            } else if (commandApdu contentEquals pollAccessToken) {
                if (intent != null && intent!!.hasExtra("accessToken") && intent!!.getStringExtra("accessToken")!!.isNotEmpty()) {
                    val accessToken = intent!!.getStringExtra("accessToken")!!
                    return accessToken.toByteArray()
                } else {
                    return byteArrayOf(0x99.toByte(), 0x99.toByte())
                }
            } else {
                return byteArrayOf(0x90.toByte(), 0x00)
            }
        } else {
            Log.i("HCE", "Command is empty")
            return byteArrayOf(0x99.toByte())
        }
        return byteArrayOf(0x00, 0x00, 0x00)
    }

    override fun onDeactivated(reason: Int) {}
}

package de.openlab.openlabflutter
import android.content.Intent
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import androidx.lifecycle.MutableLiveData
import kotlin.byteArrayOf
import kotlin.text.toByteArray

class HCEService : HostApduService() {
    var aid = byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    var hello =
        byteArrayOf(0, 0xA4.toByte(), 4, 0, 7, 0xA0.toByte(), 0, 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte())
    var tokenAvailableStart =
        byteArrayOf(0xD0.toByte(), 1)

    var getToken =
        byteArrayOf(0xD0.toByte(), 2)
    var intent: Intent? = null

    companion object {
        public val tokenLiveData = MutableLiveData<String>()
    }

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
            Log.i("HCE", "SlicedArray ${byteArrayToString(commandApdu.sliceArray(IntRange(0, 1)))}")
            Log.i("HCE", (commandApdu.sliceArray(IntRange(0, 1)) contentEquals tokenAvailableStart).toString())
            Log.i("HCE", (commandApdu.size >= 3).toString())
            if (commandApdu contentEquals hello) {
                Log.i("HCE", "Heeeeloooo")
                // intent =
                //     Intent(this, MainActivity::class.java).apply {
                //         addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                //         putExtra("hce", 1)
                //     }

                // startActivity(intent)

                Log.i("HCE", "Returning APDU bytearray")
                return byteArrayOf(0x90.toByte(), 0x00.toByte())
            } else if (commandApdu.sliceArray(IntRange(0, 1)) contentEquals tokenAvailableStart && commandApdu.size >= 3) {
                Log.i("HCE", "Metadata")
                var tokenValue: String? = HCEService.tokenLiveData.value
                var tschunkSize = commandApdu[2]
                Log.i("HCE", "Tschunksize: " + tschunkSize.toString())
                if (tokenValue != null && tokenValue.isNotEmpty()) {
                    var tokenByteArray = tokenValue.toByteArray()
                    Log.i("HCE", "Thunkcount: " + Math.floor(tokenByteArray.size / tschunkSize.toDouble()).toInt().toByte().toString())
                    // TODO: Why is it 1 too much?????
                    Log.i("HCE", "Modulooooo: " + tokenByteArray.size % tschunkSize)
                    // Log.i("HCE", "Moduloooo: " + tokenByteArray.size % tschunkSize).toByte().toString();
                    // TODO: Why is -1 neeeded????
                    return byteArrayOf(
                        Math.floor(tokenByteArray.size / tschunkSize.toDouble()).toInt().toByte(),
                        ((tokenByteArray.size % tschunkSize) - 1).toByte(),
                    ) + 0x90.toByte() + 0x00.toByte()
                } else {
                    return (byteArrayOf(0x00, 0x00, 0x6F.toByte(), 0x00))
                }
            } else if (commandApdu.sliceArray(IntRange(0, 1)) contentEquals getToken && commandApdu.size >= 6) {
                Log.i("HCE", "Send data")
                var tokenValue: String? = HCEService.tokenLiveData.value
                if (tokenValue != null && tokenValue.isNotEmpty()) {
                    var tokenByteArray = tokenValue.toByteArray()
                    var tokenIndex = commandApdu[2]
                    var tschunkSize = commandApdu[3]
                    if (tokenByteArray.size >= (tokenByteArray.size / tschunkSize) * (tokenIndex + 1)) {
                        var returnArray =
                            tokenByteArray.sliceArray(
                                IntRange(
                                    (tokenByteArray.size / tschunkSize) * tokenIndex,
                                    (tokenByteArray.size / tschunkSize) * (tokenIndex + 1),
                                ),
                            )
                        tokenIndex++
                        return returnArray + 0x90.toByte() + 0x00.toByte()
                    } else {
                        tokenIndex = 0
                        var returnArray = byteArrayOf(0x00.toByte())
                        for (tschunk in 1..tschunkSize) {
                            returnArray = returnArray + 0x00.toByte()
                        }
                        return returnArray + 0x90.toByte() + 0x00.toByte()
                    }
                } else {
                    return (byteArrayOf(0x90.toByte(), 0x00))
                }
            } else {
                return byteArrayOf(0x90.toByte(), 0x00)
            }
        } else {
            Log.i("HCE", "Command is empty")
            return byteArrayOf(0x99.toByte())
        }
    }

    override fun onDeactivated(reason: Int) {
    }
}

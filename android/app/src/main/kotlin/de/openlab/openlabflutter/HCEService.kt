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
    var pollAccessToken =
        byteArrayOf(0xD0.toByte(), 0x0F.toByte(), 0, 0, 2, 0, 8)
    var tokenAvailableStart =
        byteArrayOf(0xD0.toByte(), 0x01.toByte())
    var intent: Intent? = null
    var tokenIndex: Int = 0
    var chunkSize: Int = 256

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
            Log.i("HCE", "hello ${byteArrayToString(hello)}")
            Log.i("HCE", "pollAccessToken ${byteArrayToString(pollAccessToken)}")
            if (commandApdu contentEquals hello) {
                Log.i("HCE", "Heeeeloooo")
                intent =
                    Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra("hce", 1)
                    }

                startActivity(intent)
                return byteArrayOf(0x90.toByte(), 0x00)
            }else if(commandApdu.sliceArray(IntRange(0, 1)) contentEquals tokenAvailableStart && commandApdu.size >= 6){
                var tokenValue: String? = HCEService.tokenLiveData.value
                if (tokenValue != null && tokenValue.isNotEmpty()) {
                    var tokenByteArray = tokenValue.toByteArray()
                    return byteArrayOf(Math.floor(tokenByteArray.size / commandApdu[2].toDouble()).toInt().toByte(), (tokenByteArray.size % commandApdu[2]).toByte())
                } else {
                    return (byteArrayOf(0x00, 0x00, 0x91.toByte(), 0x00))
                }
            } else if (commandApdu contentEquals pollAccessToken) {
                var tokenValue: String? = HCEService.tokenLiveData.value
                if (tokenValue != null && tokenValue.isNotEmpty()) {
                    var tokenByteArray = tokenValue.toByteArray()
                    if(tokenByteArray.size >= (tokenByteArray.size / chunkSize) * (tokenIndex + 1)){
                        var returnArray = tokenByteArray.sliceArray(IntRange((tokenByteArray.size/chunkSize) * tokenIndex, (tokenByteArray.size/chunkSize) * (tokenIndex + 1)))
                        tokenIndex++
                        return returnArray
                    }else{
                        tokenIndex = 0;
                        return byteArrayOf(0x00);
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
        return byteArrayOf(0x00, 0x00, 0x00)
    }

    override fun onDeactivated(reason: Int) {
    }
}

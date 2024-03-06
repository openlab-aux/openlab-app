package de.openlab.openlabflutter
import android.content.Intent
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import de.openlab.openlabflutter.MainActivity

class HCEService : HostApduService() {
    var aid = byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    var hello = byteArrayOf(0, 0xA4.toByte(), 4, 0, 7, 0xA0.toByte(), 0, 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte(), 0xDA.toByte());

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
            if(commandApdu contentEquals hello){
            startActivity(
                Intent(this, MainActivity::class.java)
                    .apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra("hce", 0)
                    },
            )
            return byteArrayOf(0x90.toByte(), 0x00)
            }else {
            }
        } else {
            Log.i("HCE", "Command is empty")
        }
        return byteArrayOf(0x00, 0x00, 0x00)
    }

    override fun onDeactivated(reason: Int) {}
}

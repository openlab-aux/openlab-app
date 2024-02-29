import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

class HCEService : HostApduService() {
    var aid = byteArrayOf(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

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
        } else {
            Log.i("HCE", "Command is empty")
        }
        return byteArrayOf(0x00)
    }

    override fun onDeactivated(reason: Int) {}
}

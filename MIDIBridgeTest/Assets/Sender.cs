using UnityEngine;
using System.Collections;
using System.Net.Sockets;
using System.Net;

public class Sender : MonoBehaviour
{
    public int portNumber = 52365;

    IEnumerator Start ()
    {
        UdpClient client = new UdpClient ();

        IPEndPoint endPoint = new IPEndPoint (IPAddress.Loopback, portNumber);

        bool flipFlop = true;

        while (true) {
            MidiMessage message;

            if (flipFlop) {
                message = new MidiMessage(0x80, 44, 100);
            } else {
                message = new MidiMessage(0x90, 44, 0);
            }
            flipFlop = !flipFlop;

            client.Send(message.Bytes, 4, endPoint);

            Debug.Log ("Sent: " + message);

            yield return new WaitForSeconds(0.1f);
        }
    }
}

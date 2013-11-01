using UnityEngine;
using System.Collections;
using System.Net.Sockets;
using System.Net;

public struct MidiMessage
{
    public byte status;
    public byte data1;
    public byte data2;

    public MidiMessage(byte[] data)
    {
        status = data [0];
        data1 = data [1];
        data2 = data [2];
    }

    public override string ToString()
    {
        return "[" + status.ToString ("X") + "," + data1.ToString ("X") + "," + data2.ToString ("X") + "]";
    }
}

public class MidiBridgeTester : MonoBehaviour
{
    const int midiInPort = 52364;
    const int midiOutPort = 52365;
    UdpClient inClient;
    IPEndPoint inEndPoint;

    void Start ()
    {
        inClient = new UdpClient (midiInPort);
        inEndPoint = new IPEndPoint (IPAddress.Any, 0);
    }

    void Update ()
    {
        if (inClient.Available > 0) {
            var data = inClient.Receive(ref inEndPoint);
            if (data.Length == 4) {
                Debug.Log (new MidiMessage(data));
            }
        }
    }
}

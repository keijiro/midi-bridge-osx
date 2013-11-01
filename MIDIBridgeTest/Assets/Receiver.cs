using UnityEngine;
using System.Collections;
using System.Net.Sockets;
using System.Net;

public class Receiver : MonoBehaviour
{
    public int portNumber = 52364;

    UdpClient client;
    IPEndPoint endPoint;

    void Start ()
    {
        client = new UdpClient (portNumber);
        endPoint = new IPEndPoint (IPAddress.Any, 0);
    }

    void Update ()
    {
        if (client.Available > 0) {
            var data = client.Receive(ref endPoint);
            if (data.Length == 4) {
                Debug.Log ("recv: " + new MidiMessage(data));
            }
        }
    }
}

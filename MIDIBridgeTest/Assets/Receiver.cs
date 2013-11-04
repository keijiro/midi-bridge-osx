using UnityEngine;
using System.Collections;
using System.Net.Sockets;
using System.Net;

public class Receiver : MonoBehaviour
{
    public int portNumber = 52364;

    TcpClient client;
    bool isConnecting;

    IEnumerator Start ()
    {
        while (true) {
            while (true) {
                var tempClient = new TcpClient ();
                tempClient.BeginConnect (IPAddress.Loopback, portNumber, ConnectCallback, null);

                isConnecting = true;
                while (isConnecting)
                    yield return null;

                if (tempClient.Connected) {
                    client = tempClient;
                    break;
                }

                tempClient.Close ();

                yield return new WaitForSeconds (1.0f);
                Debug.LogWarning("Failed to connect to MIDI Bridge.");
            }

            while (client.Client.Connected) {
                yield return new WaitForSeconds (1.0f);
                try
                {
                    client.GetStream().Write (new byte[3]{0, 0, 0}, 0, 3);
                }
                catch (System.IO.IOException e)
                {
                    Debug.Log (e);
                }
            }

            Debug.LogWarning("Disconnected from MIDI Bridge.");

            client = null;
        }
    }

    void ConnectCallback(System.IAsyncResult result)
    {
        isConnecting = false;
    }

    void Update ()
    {
        if (client != null && client.Connected && client.Available > 0) {
            byte[] buffer = new byte[1024];
            int length = client.GetStream().Read (buffer, 0, buffer.Length);
            Debug.Log (length);

            client.GetStream().Write (new byte[3]{0x80, 44, 44}, 0, 3);
        }
    }
}

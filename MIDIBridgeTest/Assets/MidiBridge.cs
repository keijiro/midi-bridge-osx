using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Net.Sockets;
using System.Net;

public class MidiBridge : MonoBehaviour
{
    // Port number used to communicate with Bridge.
    const int portNumber = 52364;

    // Reference to the singleton.
    public static MidiBridge instance;

    // TCP connection.
    TcpClient tcpClient;
    bool isConnecting;

    // Message buffer.
    public Queue<MidiMessage> messages;

    // Send buffet.
    byte[] smallBuffer;

    void Awake ()
    {
        if (instance != null) {
            Destroy (gameObject);
        } else {
            instance = this;
        }

        messages = new Queue<MidiMessage> ();
        smallBuffer = new byte[4];
    }

    void Start ()
    {
        StartCoroutine (ConnectionCoroutine ());
        StartCoroutine (ReceiverCoroutine ());
    }

    public void SendMessage (byte status, byte data1, byte data2 = 0xff)
    {
        if (tcpClient != null && tcpClient.Connected) {
            smallBuffer [0] = (data2 == 0xff) ? (byte)2 : (byte)3;
            smallBuffer [1] = status;
            smallBuffer [2] = data1;
            smallBuffer [3] = data2;
            tcpClient.GetStream ().Write (smallBuffer, 0, 4);
        }
    }

    // Coroutine for managing the connection.
    IEnumerator ConnectionCoroutine ()
    {
        // "Active Sense" message for heartbeating.
        var heartbeat = new byte[4] {2, 0xff, 0xfe, 0};

        while (true) {
            // Try to open the connection.
            for (var retryCount = 0;; retryCount++) {
                // Start to connect.
                var tempClient = new TcpClient ();
                tempClient.BeginConnect (IPAddress.Loopback, portNumber, ConnectCallback, null);
                // Wait for callback.
                isConnecting = true;
                while (isConnecting) {
                    yield return null;
                }
                // Break if the connection is established.
                if (tempClient.Connected) {
                    tcpClient = tempClient;
                    break;
                }
                // Dispose the connection.
                tempClient.Close ();
                tempClient = null;
                // Show warning and wait a second.
                if (retryCount % 3 == 0) {
                    Debug.LogWarning ("Failed to connect to MIDI Bridge.");
                }
                yield return new WaitForSeconds (1.0f);
            }

            // Watch the connection.
            while (tcpClient.Connected) {
                yield return new WaitForSeconds (1.0f);
                // Send a heartbeat and break if it failed.
                try {
                    tcpClient.GetStream ().Write (heartbeat, 0, heartbeat.Length);
                } catch (System.IO.IOException exception) {
                    Debug.Log (exception);
                }
            }

            // Show warning.
            Debug.LogWarning ("Disconnected from MIDI Bridge.");

            // Close the connection and retry.
            tcpClient.Close ();
            tcpClient = null;
        }
    }

    void ConnectCallback (System.IAsyncResult result)
    {
        isConnecting = false;
    }

    // Coroutine for receiving messages.
    IEnumerator ReceiverCoroutine ()
    {
        byte[] buffer = new byte[2048];

        while (true) {
            // Do nothing if the connection is not ready.
            if (tcpClient == null || !tcpClient.Connected || tcpClient.Available < 4) {
                yield return null;
                continue;
            }

            // Receive data from the socket.
            var available = Mathf.Min ((tcpClient.Available / 4) * 4, buffer.Length);
            var bufferFilled = tcpClient.GetStream ().Read (buffer, 0, available);

            for (var offset = 0; offset < bufferFilled; offset += 4) {
                var length = buffer [offset];
                if (length == 2) {
                    messages.Enqueue (new MidiMessage (buffer [offset + 1], buffer [offset + 2]));
                } else if (length == 3) {
                    messages.Enqueue (new MidiMessage (buffer [offset + 1], buffer [offset + 2], buffer [offset + 3]));
                }
            }

            yield return null;
        }
    }
}

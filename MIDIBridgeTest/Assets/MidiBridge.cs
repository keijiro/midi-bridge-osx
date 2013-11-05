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
        smallBuffer = new byte[3];
    }

    void Start ()
    {
        StartCoroutine (ConnectionCoroutine ());
        StartCoroutine (ReceiverCoroutine ());
    }

    public void SendMessage(byte status, byte data1, byte data2 = 0xff)
    {
        if (tcpClient != null && tcpClient.Connected) {
            smallBuffer [0] = status;
            smallBuffer [1] = data1;
            smallBuffer [2] = data2;
            tcpClient.GetStream ().Write (smallBuffer, 0, (data2 == 0xff) ? 2 : 3);
        }
    }

    // Coroutine for managing the connection.
    IEnumerator ConnectionCoroutine ()
    {
        // "Active Sense" message for heartbeating.
        var heartbeat = new byte[2] {0xff, 0xfe};

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
            // Do nothing if the connection in unavailable.
            if (tcpClient == null || !tcpClient.Connected || tcpClient.Available == 0) {
                yield return null;
                continue;
            }

            // Receive messages from the socket.
            int length = tcpClient.GetStream ().Read (buffer, 0, buffer.Length);
            int offset = 0;

            // Look for the first message.
            while (offset < length && buffer[offset] < 0x80) {
                offset++;
            }

            while (offset < length) {
                var status = buffer [offset++];

                if (offset == length || buffer [offset] > 0x7f) {
                    messages.Enqueue (new MidiMessage (status));
                    continue;
                }

                var data1 = buffer [offset++];

                if (offset == length || buffer [offset] > 0x7f) {
                    messages.Enqueue (new MidiMessage (status, data1));
                    continue;
                }

                var data2 = buffer [offset++];
                while (offset < length && buffer[offset] < 0x80) {
                    offset++;
                }
                
                messages.Enqueue (new MidiMessage (status, data1, data2));
            }

            yield return null;
        }
    }
}

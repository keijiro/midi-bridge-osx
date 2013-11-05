using UnityEngine;
using System.Collections;
using System.Net.Sockets;
using System.Net;

public class Tester : MonoBehaviour
{
    IEnumerator Start ()
    {
        while (true) {
            MidiBridge.instance.Send(0x90, 50, 100);
            yield return new WaitForSeconds(0.5f);
            MidiBridge.instance.Send(0x80, 50, 0);
            yield return new WaitForSeconds(0.5f);
        }
    }

    void Update ()
    {
        while (MidiBridge.instance.messages.Count > 0) {
            Debug.Log (MidiBridge.instance.messages.Dequeue());
        }
    }
}

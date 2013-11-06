using UnityEngine;
using System.Collections;

public class Tester : MonoBehaviour
{
    [Range(0, 15)]
    public int channel = 0;

    [Range(0, 127)]
    public int note = 50;

    IEnumerator Start ()
    {
        while (true) {
            var c = channel;
            var n = note;

            MidiBridge.instance.Send(0x90 + c, n, 100);
            yield return new WaitForSeconds(0.1f);

            MidiBridge.instance.Send(0x80 + c, n, 0);
            yield return new WaitForSeconds(0.1f);
        }
    }

    void Update ()
    {
        while (MidiBridge.instance.incomingMessageQueue.Count > 0) {
            Debug.Log (MidiBridge.instance.incomingMessageQueue.Dequeue());
        }
    }
}

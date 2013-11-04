public struct MidiMessage
{
    public byte status;
    public byte data1;
    public byte data2;

    public MidiMessage (byte status, byte data1, byte data2)
    {
        this.status = status;
        this.data1 = data1;
        this.data2 = data2;
    }

    public MidiMessage (byte[] data)
    {
        status = data [0];
        data1 = data [1];
        data2 = (data.Length > 2) ? data [2] : (byte)0;
    }

    public byte[] Bytes {
        get {
            return new byte[] { status, data1, data2 };
        }
    }

    public override string ToString ()
    {
        return "[" + status.ToString ("X") + "," + data1.ToString ("X") + "," + data2.ToString ("X") + "]";
    }
}

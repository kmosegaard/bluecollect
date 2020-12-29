module bc.hci;

import core.sys.posix.sys.types;
import core.sys.linux.errno;
import core.sys.linux.sys.socket;

import std.algorithm;
import std.array;
import std.bitmanip;
import std.conv;
import std.digest;

enum int BTPROTO_HCI = 1;

enum HCI_CHANNEL : ushort
{
    USER = 1
}

extern (C) struct sockaddr_hci
{
    sa_family_t hci_family;
    ushort hci_dev;
    ushort hci_channel;
}

enum PacketType
{
    command = 0x01,
    acl = 0x02,
    event = 0x04
}

enum CommandCode : ushort
{
    setEventMask = 0x0c01,
    reset = 0x0c03,
    writeLeHostSupported = 0x0c6d,
    leSetEventMask = 0x2001,
    leSetRandomAddress = 0x2005,
    leSetScanParameters = 0x200b,
    leSetScanEnable = 0x200c
}

enum EventCode
{
    commandComplete = 0x0e,
    commandStatus = 0x0f,
    leMeta = 0x3e
}

enum LEMetaSubEventCode
{
    advertisingReport = 0x02
}

enum AdType
{
    flags = 0x01,
    more16BitService = 0x02,
    complete16BitService = 0x03,
    more32BitService = 0x04,
    complete32BitService = 0x05,
    more128BitService = 0x06,
    complete128BitService = 0x07,
    shortenedLocalName = 0x08,
    completeLocalName = 0x09,
    txPower = 0x0a,
    classOfdevice = 0x0d,
    pairingHash = 0x0e,
    pairingRandomizer = 0x0f,
    smTk = 0x10,
    smOobFlags = 0x11,
    slaveConnInterval = 0x12,
    list16bitServiceSol = 0x14,
    list128bitServiceSol = 0x15,
    serviceData = 0x16,
    publicTargetAddr = 0x17,
    randomTargetAddr = 0x18,
    appearance = 0x19,
    advInterval = 0x1a,
    deviceAddress = 0x1b,
    leRole = 0x1c,
    pairingHash256 = 0x1d,
    pairingRandomizer256 = 0x1e,
    list32BitServiceSol = 0x1f,
    serviceData32 = 0x20,
    serviceData128 = 0x21,
    secureConnConfirm = 0x22,
    secureConnRandom = 0x23,
    uri = 0x24,
    indoorPosit = 0x25,
    transportDiscoveryData = 0x26,
    leSupportedFeatures = 0x27,
    channelMapUpdate = 0x28,
    meshPbAdv = 0x29,
    meshMessage = 0x2a,
    meshBeacon = 0x2b,
    data3d = 0x3d,
    manufacturerSpecific = 0xff
}

class Channel
{
    private int fd;
    private ubyte[512] buffer;

    void initialize()
    {
        fd = create(0);
        if (fd < 0)
        {
            return;
        }

        write(reset());
        auto response = read();

        write(writeLeHostSupported());
        response = read();

        write(setEventMask());
        response = read();

        write(leSetEventMask());
        response = read();
    }

    ubyte[] read()
    {
        auto responseLength = read(buffer);
        if (responseLength < 0)
        {
            return null;
        }
        return buffer[0 .. responseLength];
    }

    void startScan()
    {
        write(leSetScanParameters());
        auto resp = read();

        write(leSetScanEnabled(true));
        resp = read();
    }

    void stopScan()
    {
        write(leSetScanEnabled(false));
        auto resp = read();
    }

    int create(ushort hciDevice)
    {
        import core.sys.linux.sys.time;

        int fd = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
        if (fd < 0)
        {
            return -errno;
        }

        sockaddr_hci addr;
        addr.hci_family = AF_BLUETOOTH;
        addr.hci_dev = hciDevice;
        addr.hci_channel = HCI_CHANNEL.USER;

        int err = bind(fd, cast(sockaddr*)(&addr), addr.sizeof);
        if (err < 0)
        {
            return -errno;
        }

        timeval tv;
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        err = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, tv.sizeof);
        if (err < 0)
        {
            return -errno;
        }

        return fd;
    }

    private int write(const(void)[] payload)
    {
        import core.sys.linux.unistd : write;

        if (fd < 0)
        {
            return 0;
        }

        long err = write(fd, payload.ptr, payload.length);
        if (err != payload.length)
        {
        }

        return cast(int)(err);
    }

    private ssize_t read(ubyte[] buffer)
    {
        import core.sys.linux.unistd : read;

        if (fd < 0)
        {
            return 0;
        }

        auto res = read(fd, buffer.ptr, buffer.length);
        if (res == -1)
        {
            return -errno;
        }

        return res;
    }

    private ubyte[4] reset()
    {
        ubyte[4] command;
        command[0] = PacketType.command;
        command[1] = cast(ubyte)(CommandCode.reset & 0xFF);
        command[2] = cast(ubyte)(CommandCode.reset >> 8);
        command[3] = 0x00;
        return command;
    }

    private ubyte[6] writeLeHostSupported()
    {
        ubyte[6] command;
        command[0] = PacketType.command;
        command[1] = cast(ubyte)(CommandCode.writeLeHostSupported & 0xFF);
        command[2] = cast(ubyte)(CommandCode.writeLeHostSupported >> 8);
        command[3] = 0x02;
        command[4] = 0x01; // LE Supported Host enabled
        command[5] = 0x00; // Simultaneous LE Host parameter
        return command;
    }

    private ubyte[12] setEventMask()
    {
        ubyte[12] command;
        command[0] = PacketType.command;
        command[1] = cast(ubyte)(CommandCode.setEventMask & 0xFF);
        command[2] = cast(ubyte)(CommandCode.setEventMask >> 8);
        command[3] = 0x08;
        command[4] = 0xFF;
        command[5] = 0xFF;
        command[6] = 0xFF;
        command[7] = 0xFF;
        command[8] = 0xFF;
        command[9] = 0xFF;
        command[10] = 0xFF;
        command[11] = 0x3F;
        return command;
    }

    private ubyte[12] leSetEventMask()
    {
        ubyte[12] command;
        command[0] = PacketType.command;
        command[1] = cast(ubyte)(CommandCode.leSetEventMask & 0xFF);
        command[2] = cast(ubyte)(CommandCode.leSetEventMask >> 8);
        command[3] = 0x08;
        command[4] = 0x1F;
        command[5] = 0x00;
        command[6] = 0x00;
        command[7] = 0x00;
        command[8] = 0x00;
        command[9] = 0x00;
        command[10] = 0x00;
        command[11] = 0x00;
        return command;
    }

    private ubyte[11] leSetScanParameters()
    {
        ubyte[11] command;
        command[0] = PacketType.command;
        command[1] = cast(ubyte)(CommandCode.leSetScanParameters & 0xFF);
        command[2] = cast(ubyte)(CommandCode.leSetScanParameters >> 8);
        command[3] = 0x07;
        command[4] = 0x00; // Passive scanning
        command[5] = 0x10; // Scan interval
        command[6] = 0x00;
        command[7] = 0x10; // Scan window
        command[8] = 0x00;
        command[9] = 0x00; // Own address type
        command[10] = 0x00; // Filter policy
        return command;
    }

    private ubyte[6] leSetScanEnabled(bool scanEnabled)
    {
        ubyte[6] command;
        command[0] = PacketType.command;
        command[1] = cast(ubyte)(CommandCode.leSetScanEnable & 0xFF);
        command[2] = cast(ubyte)(CommandCode.leSetScanEnable >> 8);
        command[3] = 0x02;
        command[4] = scanEnabled ? 0x01 : 0x00; // Scan enabled
        command[5] = 0x00; // Filter duplicates
        return command;
    }
}

class AdStructure
{
    AdType type;
    ubyte[] data;
}

class AdvertisingReport
{
    ubyte advType;
    ubyte[] btAddress;
    AdStructure[] adStructures;
    ubyte rssi;

    string getAddress()
    {
        return toHexString(btAddress);
    }
}

class BLEParser
{
    public AdvertisingReport[] handleAdvertisementReport(ubyte[] advertisementData)
    {
        if (advertisementData == null)
        {
            return null;
        }

        if (advertisementData[0] != PacketType.event)
        {
            return null;
        }

        auto code = cast(EventCode)(advertisementData[1]);
        if (code != EventCode.leMeta)
        {
            return null;
        }

        auto parametersLength = advertisementData[2];
        if (parametersLength != advertisementData.length - 3)
        {
            return null;
        }

        auto subEvent = cast(LEMetaSubEventCode) advertisementData[3];
        if (subEvent != LEMetaSubEventCode.advertisingReport)
        {
            return null;
        }

        auto numberOfReports = advertisementData[4];
        auto reports = new AdvertisingReport[numberOfReports];

        auto cursor = 5;
        for (auto i = 0; i < numberOfReports; i++)
        {
            auto report = new AdvertisingReport();

            auto advType = advertisementData[cursor];
            report.advType = advType;
            cursor++;

            auto addressType = advertisementData[cursor];
            cursor++;

            auto address = reverse(advertisementData[cursor .. cursor + 6]);
            report.btAddress = address;
            cursor += 6;

            auto dataLength = advertisementData[cursor];
            cursor++;

            if (dataLength > 0)
            {
                auto dataEnd = cursor + dataLength;
                while (cursor < dataEnd)
                {
                    auto adStructure = new AdStructure();

                    auto subDataLength = advertisementData[cursor];
                    cursor++;

                    auto subDataType = advertisementData[cursor];
                    adStructure.type = cast(AdType)(subDataType);
                    cursor++;
                    auto subData = advertisementData[cursor .. cursor + subDataLength - 1];
                    adStructure.data = subData;
                    cursor += subDataLength - 1;

                    report.adStructures ~= adStructure;

                }
            }

            ubyte rssi = advertisementData[cursor];
            report.rssi = rssi;
            cursor++;

            reports[i] = report;
        }

        return reports;
    }
}

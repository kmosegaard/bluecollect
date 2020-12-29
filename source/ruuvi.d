module bc.ruuvi;

import std.array;
import std.format;

enum ruuviManufacturerId = 0x0499;
enum ruuviProtocolVersionV5 = 0x05;

struct RuuviMessage
{
    bool valid;
    string address;
    int rssi;
    float temperature;
    float humidity;
    uint pressure;
    short accelerationX;
    short accelerationY;
    short accelerationZ;
    short voltage;
    byte transmitPower;
    ubyte movementCounter;
    ushort sequence;
}

bool isRuuviMessage(ubyte[] data)
{
    if (data.length != 26)
    {
        return false;
    }

    auto manufacturerId = getManufacturerId(data[0 .. 2]);
    if (manufacturerId != ruuviManufacturerId)
    {
        return false;
    }

    return true;
}

RuuviMessage parse(ubyte[] address, int rssi, ubyte[] data)
{
    RuuviMessage message = {valid: false};

    auto protocolVersion = getProtocolVersion(data[2]);
    if (protocolVersion != ruuviProtocolVersionV5)
    {
        return message;
    }

    message.valid = true;
    message.address = getAddressStr(address);
    message.rssi = rssi;
    message.temperature = getTemperatureV5(data[3 .. 5]);
    message.humidity = getHumidityV5(data[5 .. 7]);
    message.pressure = getPressureV5(data[7 .. 9]);
    message.accelerationX = getAccelerationXV5(data[9 .. 11]);
    message.accelerationY = getAccelerationYV5(data[11 .. 13]);
    message.accelerationZ = getAccelerationZV5(data[13 .. 15]);
    message.voltage = getVoltageV5(data[15 .. 17]);
    message.transmitPower = getTransmitPowerV5(data[16]);
    message.movementCounter = getMovementCounterV5(data[17]);
    message.sequence = getSequenceV5(data[18 .. 20]);

    return message;
}

string getAddressStr(ubyte[] address)
{
    auto addressStr = appender!string;
    addressStr.reserve(17);

    auto sepCount = 0;
    foreach (adr; address)
    {
        addressStr.put(format("%02X", adr));
        if (sepCount < 5)
        {
            addressStr.put(':');
            sepCount++;
        }
    }

    return addressStr.data;
}

short getManufacturerId(ubyte[] data)
{
    assert(data.length == 2);
    short res = cast(short)(data[1] << 8);
    res += cast(short)(data[0]);
    return res;
}

ubyte getProtocolVersion(ubyte data)
{
    return data;
}

float getTemperatureV5(ubyte[] data)
{
    assert(data.length == 2);
    short res = cast(short)(data[0] << 8);
    res += cast(short)(data[1]);
    return res * 0.005;
}

float getHumidityV5(ubyte[] data)
{
    assert(data.length == 2);
    ushort res = cast(ushort)(data[0] << 8);
    res += cast(ushort)(data[1]);
    return res * 0.0025;
}

uint getPressureV5(ubyte[] data)
{
    assert(data.length == 2);
    uint res = cast(uint)(data[0] << 8);
    res += cast(uint)(data[1]);
    res += 50000;
    return res;
}

short getAccelerationXV5(ubyte[] data)
{
    assert(data.length == 2);
    short res = cast(short)(data[0] << 8);
    res += cast(short)(data[1]);
    return res;
}

short getAccelerationYV5(ubyte[] data)
{
    assert(data.length == 2);
    short res = cast(short)(data[0] << 8);
    res += cast(short)(data[1]);
    return res;
}

short getAccelerationZV5(ubyte[] data)
{
    assert(data.length == 2);
    short res = cast(short)(data[0] << 8);
    res += cast(short)(data[1]);
    return res;
}

short getVoltageV5(ubyte[] data)
{
    assert(data.length == 2);
    short res = cast(short)(data[0] << 3);
    res += cast(short)(data[1] >> 5);
    res += 1600;
    return res;
}

byte getTransmitPowerV5(ubyte data)
{
    byte res = (data & 0x1F);
    res += res;
    res -= 0x28;
    return res;
}

ubyte getMovementCounterV5(ubyte data)
{
    return data;
}

ushort getSequenceV5(ubyte[] data)
{
    assert(data.length == 2);
    ushort res = cast(ushort)(data[0] << 8);
    res += cast(ushort)(data[1]);
    return res;
}

unittest
{
    // Valid data
    ubyte[] address = [0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F];
    ubyte[] data = [
        0x99, 0x04, 0x05, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C, 0x00, 0x04, 0xFF,
        0xFC, 0x04, 0x0C, 0xAC, 0x36, 0x42, 0x00, 0xCD, 0xCB, 0xB8, 0x33, 0x4C,
        0x88, 0x4F
    ];
    assert(true == isRuuviMessage(data));

    auto msg = parse(address, 100, data);
    assert(24.3f == msg.temperature);
    assert(53.49f == msg.humidity);
    assert(100044 == msg.pressure);
    assert(4 == msg.accelerationX);
    assert(-4 == msg.accelerationY);
    assert(1036 == msg.accelerationZ);
    assert(2977 == msg.voltage);
    assert(4 == msg.transmitPower);
    assert(66 == msg.movementCounter);
    assert(205 == msg.sequence);

    // Maximum values
    data = [
        0x99, 0x04, 0x05, 0x7F, 0xFF, 0xFF, 0xFE, 0xFF, 0xFE, 0x7F, 0xFF, 0x7F,
        0xFF, 0x7F, 0xFF, 0xFF, 0xDE, 0xFE, 0xFF, 0xFE, 0xCB, 0xB8, 0x33, 0x4C,
        0x88, 0x4F
    ];
    assert(true == isRuuviMessage(data));

    msg = parse(address, 100, data);
    assert(163.835f == msg.temperature);
    assert(163.835f == msg.humidity);
    assert(115534 == msg.pressure);
    assert(32767 == msg.accelerationX);
    assert(32767 == msg.accelerationY);
    assert(32767 == msg.accelerationZ);
    assert(3646 == msg.voltage);
    assert(20 == msg.transmitPower);
    assert(254 == msg.movementCounter);
    assert(65534 == msg.sequence);

    // Minimum values
    data = [
        0x99, 0x04, 0x05, 0x80, 0x01, 0x00, 0x00, 0x00, 0x00, 0x80, 0x01, 0x80,
        0x01, 0x80, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0xCB, 0xB8, 0x33, 0x4C,
        0x88, 0x4F
    ];
    assert(true == isRuuviMessage(data));

    msg = parse(address, 100, data);
    assert(-163.835f == msg.temperature);
    assert(0.0f == msg.humidity);
    assert(50000 == msg.pressure);
    assert(-32767 == msg.accelerationX);
    assert(-32767 == msg.accelerationY);
    assert(-32767 == msg.accelerationZ);
    assert(1600 == msg.voltage);
    assert(-40 == msg.transmitPower);
    assert(0 == msg.movementCounter);
    assert(0 == msg.sequence);
}

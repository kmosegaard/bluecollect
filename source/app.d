import core.sys.posix.signal;

import std.algorithm : find;
import std.range : empty;
import std.stdio;

import bc.config;
import bc.database;
import bc.hci;
import bc.ruuvi;

__gshared bool terminated;
extern (C) void handleSigterm(int)
{
    terminated = true;
}

int main()
{
    auto config = Config.load();

    auto db = new Database;
    auto hci = new Channel;
    auto parser = new BLEParser;

    db.open();
    db.initialize(config);

    hci.initialize();
    hci.startScan();

    bsd_signal(SIGTERM, &handleSigterm);

    while (!terminated)
    {
        auto buffer = hci.read();
        auto reports = parser.handleAdvertisementReport(buffer);

        if (reports == null)
            continue;
        foreach (report; reports)
        {
            auto devices = config.devices;
            auto device = devices.find!("a.address == b")(report.getAddress());
            if (device.empty)
                continue;

            foreach (structure; report.adStructures)
            {
                if (structure.type != AdType.manufacturerSpecific)
                {
                    continue;
                }

                if (!isRuuviMessage(structure.data))
                {
                    continue;
                }

                auto message = parse(report.btAddress, report.rssi, structure.data);
                if (!message.valid)
                {
                    continue;
                }

                db.insert(device[0].tableName, message.temperature, message.humidity);
            }
        }
    }

    hci.stopScan();
    db.close();

    return 0;
}

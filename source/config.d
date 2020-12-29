module bc.config;

import std.array;
import std.conv;
import std.file;
import std.json;
import std.stdio;

struct Device
{
    string name;
    string address;
    string tableName;
}

struct Config
{
    Device[] devices;

    static immutable defaultPath = "config.json";

    static Config load(string path = defaultPath)
    {
        Config config;
        if (path.exists)
        {
            config.loadFromFile(path);
        }

        return config;
    }

private:
    void loadFromFile(string path)
    {
        auto file = readText(path);
        auto content = parseJSON(file);
        auto configDevices = content["devices"].array;
        foreach (device; configDevices)
        {
            Device d;
            d.name = device["name"].str;
            d.address = device["address"].str.replace(":", "");
            d.tableName = device["table_name"].str;
            devices ~= d;
        }
    }
}

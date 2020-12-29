module bc.database;

import std.datetime;
import std.format;
import std.string;
import std.stdio;

import bc.config;

import duckdb;

class Database
{
    private duckdb_database db;
    private duckdb_connection conn;

    void open()
    {
        if (duckdb_open("db.duckdb", &db) == duckdb_state.DuckDBError)
        {
            writefln("Error when opening db.");
            return;
        }

        if (duckdb_connect(db, &conn) == duckdb_state.DuckDBError)
        {
            writefln("Error when connecting to db.");
            return;
        }
    }

    void initialize(ref Config config)
    {
        foreach (device; config.devices)
        {
            enum createTbl = "CREATE TABLE IF NOT EXISTS %s(t LONG, temperature FLOAT, humidity FLOAT)";
            auto state = duckdb_query(conn, createTbl.format(device.tableName).toStringz(), null);
            if (state == duckdb_state.DuckDBError)
            {
                writefln("Error when creating table.");
            }
        }
    }

    void insert(string name, double temperature, double humidity)
    {
        duckdb_appender appender;
        if (duckdb_appender_create(conn, null, "%s".format(name).toStringz,
                &appender) == duckdb_state.DuckDBError)
        {
            writefln("Error when creating appender.");
            return;
        }

        auto t = (Clock.currTime() - SysTime.fromUnixTime(0)).total!"msecs";
        duckdb_append_int64(appender, t);
        duckdb_append_float(appender, temperature);
        duckdb_append_float(appender, humidity);
        duckdb_appender_end_row(appender);
        duckdb_appender_destroy(&appender);
    }

    void close()
    {
        duckdb_disconnect(&conn);
        duckdb_close(&db);
    }
}

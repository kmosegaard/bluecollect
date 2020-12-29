//===----------------------------------------------------------------------===//
//
//                         DuckDB
//
// duckdb.h
//
//
//===----------------------------------------------------------------------===//

import core.stdc.config;

extern (C):

// duplicate of duckdb/main/winapi.hpp

// duplicate of duckdb/common/constants.hpp

enum DUCKDB_API_0_3_1 = 1;

enum DUCKDB_API_0_3_2 = 2;

enum DUCKDB_API_LATEST = DUCKDB_API_0_3_2;

enum DUCKDB_API_VERSION = DUCKDB_API_LATEST;

//===--------------------------------------------------------------------===//
// Type Information
//===--------------------------------------------------------------------===//
alias idx_t = c_ulong;

enum DUCKDB_TYPE
{
    DUCKDB_TYPE_INVALID = 0,
    // bool
    DUCKDB_TYPE_BOOLEAN = 1,
    // int8_t
    DUCKDB_TYPE_TINYINT = 2,
    // int16_t
    DUCKDB_TYPE_SMALLINT = 3,
    // int32_t
    DUCKDB_TYPE_INTEGER = 4,
    // int64_t
    DUCKDB_TYPE_BIGINT = 5,
    // uint8_t
    DUCKDB_TYPE_UTINYINT = 6,
    // uint16_t
    DUCKDB_TYPE_USMALLINT = 7,
    // uint32_t
    DUCKDB_TYPE_UINTEGER = 8,
    // uint64_t
    DUCKDB_TYPE_UBIGINT = 9,
    // float
    DUCKDB_TYPE_FLOAT = 10,
    // double
    DUCKDB_TYPE_DOUBLE = 11,
    // duckdb_timestamp
    DUCKDB_TYPE_TIMESTAMP = 12,
    // duckdb_date
    DUCKDB_TYPE_DATE = 13,
    // duckdb_time
    DUCKDB_TYPE_TIME = 14,
    // duckdb_interval
    DUCKDB_TYPE_INTERVAL = 15,
    // duckdb_hugeint
    DUCKDB_TYPE_HUGEINT = 16,
    // const char*
    DUCKDB_TYPE_VARCHAR = 17,
    // duckdb_blob
    DUCKDB_TYPE_BLOB = 18
}

alias duckdb_type = DUCKDB_TYPE;

//! Days are stored as days since 1970-01-01
//! Use the duckdb_from_date/duckdb_to_date function to extract individual information
struct duckdb_date
{
    int days;
}

struct duckdb_date_struct
{
    int year;
    byte month;
    byte day;
}

//! Time is stored as microseconds since 00:00:00
//! Use the duckdb_from_time/duckdb_to_time function to extract individual information
struct duckdb_time
{
    long micros;
}

struct duckdb_time_struct
{
    byte hour;
    byte min;
    byte sec;
    int micros;
}

//! Timestamps are stored as microseconds since 1970-01-01
//! Use the duckdb_from_timestamp/duckdb_to_timestamp function to extract individual information
struct duckdb_timestamp
{
    long micros;
}

struct duckdb_timestamp_struct
{
    duckdb_date_struct date;
    duckdb_time_struct time;
}

struct duckdb_interval
{
    int months;
    int days;
    long micros;
}

//! Hugeints are composed in a (lower, upper) component
//! The value of the hugeint is upper * 2^64 + lower
//! For easy usage, the functions duckdb_hugeint_to_double/duckdb_double_to_hugeint are recommended
struct duckdb_hugeint
{
    ulong lower;
    long upper;
}

struct duckdb_blob
{
    void* data;
    idx_t size;
}

struct duckdb_column
{
    // deprecated, use duckdb_column_data
    void* __deprecated_data;
    // deprecated, use duckdb_nullmask_data
    bool* __deprecated_nullmask;
    // deprecated, use duckdb_column_type
    duckdb_type __deprecated_type;
    // deprecated, use duckdb_column_name
    char* __deprecated_name;

    void* internal_data;
}

struct duckdb_result
{
    // deprecated, use duckdb_column_count
    idx_t __deprecated_column_count;
    // deprecated, use duckdb_row_count
    idx_t __deprecated_row_count;
    // deprecated, use duckdb_rows_changed
    idx_t __deprecated_rows_changed;
    // deprecated, use duckdb_column_ family of functions
    duckdb_column* __deprecated_columns;
    // deprecated, use duckdb_result_error
    char* __deprecated_error_message;

    void* internal_data;
}

alias duckdb_database = void*;
alias duckdb_connection = void*;
alias duckdb_prepared_statement = void*;
alias duckdb_appender = void*;
alias duckdb_arrow = void*;
alias duckdb_config = void*;
alias duckdb_arrow_schema = void*;
alias duckdb_arrow_array = void*;

enum duckdb_state
{
    DuckDBSuccess = 0,
    DuckDBError = 1
}

//===--------------------------------------------------------------------===//
// Open/Connect
//===--------------------------------------------------------------------===//

/*!
Creates a new database or opens an existing database file stored at the the given path.
If no path is given a new in-memory database is created instead.

* path: Path to the database file on disk, or `nullptr` or `:memory:` to open an in-memory database.
* out_database: The result database object.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_open (const(char)* path, duckdb_database* out_database);

/*!
Extended version of duckdb_open. Creates a new database or opens an existing database file stored at the the given path.

* path: Path to the database file on disk, or `nullptr` or `:memory:` to open an in-memory database.
* out_database: The result database object.
* config: (Optional) configuration used to start up the database system.
* out_error: If set and the function returns DuckDBError, this will contain the reason why the start-up failed.
Note that the error must be freed using `duckdb_free`.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_open_ext (
    const(char)* path,
    duckdb_database* out_database,
    duckdb_config config,
    char** out_error);

/*!
Closes the specified database and de-allocates all memory allocated for that database.
This should be called after you are done with any database allocated through `duckdb_open`.
Note that failing to call `duckdb_close` (in case of e.g. a program crash) will not cause data corruption.
Still it is recommended to always correctly close a database object after you are done with it.

* database: The database object to shut down.
*/
void duckdb_close (duckdb_database* database);

/*!
Opens a connection to a database. Connections are required to query the database, and store transactional state
associated with the connection.

* database: The database file to connect to.
* out_connection: The result connection object.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_connect (duckdb_database database, duckdb_connection* out_connection);

/*!
Closes the specified connection and de-allocates all memory allocated for that connection.

* connection: The connection to close.
*/
void duckdb_disconnect (duckdb_connection* connection);

//===--------------------------------------------------------------------===//
// Configuration
//===--------------------------------------------------------------------===//
/*!
Initializes an empty configuration object that can be used to provide start-up options for the DuckDB instance
through `duckdb_open_ext`.

This will always succeed unless there is a malloc failure.

* out_config: The result configuration object.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_create_config (duckdb_config* out_config);

/*!
This returns the total amount of configuration options available for usage with `duckdb_get_config_flag`.

This should not be called in a loop as it internally loops over all the options.

* returns: The amount of config options available.
*/
size_t duckdb_config_count ();

/*!
Obtains a human-readable name and description of a specific configuration option. This can be used to e.g.
display configuration options. This will succeed unless `index` is out of range (i.e. `>= duckdb_config_count`).

The result name or description MUST NOT be freed.

* index: The index of the configuration option (between 0 and `duckdb_config_count`)
* out_name: A name of the configuration flag.
* out_description: A description of the configuration flag.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_get_config_flag (size_t index, const(char*)* out_name, const(char*)* out_description);

/*!
Sets the specified option for the specified configuration. The configuration option is indicated by name.
To obtain a list of config options, see `duckdb_get_config_flag`.

In the source code, configuration options are defined in `config.cpp`.

This can fail if either the name is invalid, or if the value provided for the option is invalid.

* duckdb_config: The configuration object to set the option on.
* name: The name of the configuration flag to set.
* option: The value to set the configuration flag to.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_set_config (duckdb_config config, const(char)* name, const(char)* option);

/*!
Destroys the specified configuration option and de-allocates all memory allocated for the object.

* config: The configuration object to destroy.
*/
void duckdb_destroy_config (duckdb_config* config);

//===--------------------------------------------------------------------===//
// Query Execution
//===--------------------------------------------------------------------===//
/*!
Executes a SQL query within a connection and stores the full (materialized) result in the out_result pointer.
If the query fails to execute, DuckDBError is returned and the error message can be retrieved by calling
`duckdb_result_error`.

Note that after running `duckdb_query`, `duckdb_destroy_result` must be called on the result object even if the
query fails, otherwise the error stored within the result will not be freed correctly.

* connection: The connection to perform the query in.
* query: The SQL query to run.
* out_result: The query result.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_query (duckdb_connection connection, const(char)* query, duckdb_result* out_result);

/*!
Closes the result and de-allocates all memory allocated for that connection.

* result: The result to destroy.
*/
void duckdb_destroy_result (duckdb_result* result);

/*!
Returns the column name of the specified column. The result should not need be freed; the column names will
automatically be destroyed when the result is destroyed.

Returns `NULL` if the column is out of range.

* result: The result object to fetch the column name from.
* col: The column index.
* returns: The column name of the specified column.
*/
const(char)* duckdb_column_name (duckdb_result* result, idx_t col);

/*!
Returns the column type of the specified column.

Returns `DUCKDB_TYPE_INVALID` if the column is out of range.

* result: The result object to fetch the column type from.
* col: The column index.
* returns: The column type of the specified column.
*/
duckdb_type duckdb_column_type (duckdb_result* result, idx_t col);

/*!
Returns the number of columns present in a the result object.

* result: The result object.
* returns: The number of columns present in the result object.
*/
idx_t duckdb_column_count (duckdb_result* result);

/*!
Returns the number of rows present in a the result object.

* result: The result object.
* returns: The number of rows present in the result object.
*/
idx_t duckdb_row_count (duckdb_result* result);

/*!
Returns the number of rows changed by the query stored in the result. This is relevant only for INSERT/UPDATE/DELETE
queries. For other queries the rows_changed will be 0.

* result: The result object.
* returns: The number of rows changed.
*/
idx_t duckdb_rows_changed (duckdb_result* result);

/*!
Returns the data of a specific column of a result in columnar format. This is the fastest way of accessing data in a
query result, as no conversion or type checking must be performed (outside of the original switch). If performance
is a concern, it is recommended to use this API over the `duckdb_value` functions.

The function returns a dense array which contains the result data. The exact type stored in the array depends on the
corresponding duckdb_type (as provided by `duckdb_column_type`). For the exact type by which the data should be
accessed, see the comments in [the types section](types) or the `DUCKDB_TYPE` enum.

For example, for a column of type `DUCKDB_TYPE_INTEGER`, rows can be accessed in the following manner:
```c
int32_t *data = (int32_t *) duckdb_column_data(&result, 0);
printf("Data for row %d: %d\n", row, data[row]);
```

* result: The result object to fetch the column data from.
* col: The column index.
* returns: The column data of the specified column.
*/
void* duckdb_column_data (duckdb_result* result, idx_t col);

/*!
Returns the nullmask of a specific column of a result in columnar format. The nullmask indicates for every row
whether or not the corresponding row is `NULL`. If a row is `NULL`, the values present in the array provided
by `duckdb_column_data` are undefined.

```c
int32_t *data = (int32_t *) duckdb_column_data(&result, 0);
bool *nullmask = duckdb_nullmask_data(&result, 0);
if (nullmask[row]) {
    printf("Data for row %d: NULL\n", row);
} else {
    printf("Data for row %d: %d\n", row, data[row]);
}
```

* result: The result object to fetch the nullmask from.
* col: The column index.
* returns: The nullmask of the specified column.
*/
bool* duckdb_nullmask_data (duckdb_result* result, idx_t col);

/*!
Returns the error message contained within the result. The error is only set if `duckdb_query` returns `DuckDBError`.

The result of this function must not be freed. It will be cleaned up when `duckdb_destroy_result` is called.

* result: The result object to fetch the nullmask from.
* returns: The error of the result.
*/
char* duckdb_result_error (duckdb_result* result);

//===--------------------------------------------------------------------===//
// Result Functions
//===--------------------------------------------------------------------===//

// Safe fetch functions
// These functions will perform conversions if necessary.
// On failure (e.g. if conversion cannot be performed or if the value is NULL) a default value is returned.
// Note that these functions are slow since they perform bounds checking and conversion
// For fast access of values prefer using duckdb_column_data and duckdb_nullmask_data

/*!
 * returns: The boolean value at the specified location, or false if the value cannot be converted.
 */
bool duckdb_value_boolean (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The int8_t value at the specified location, or 0 if the value cannot be converted.
 */
byte duckdb_value_int8 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The int16_t value at the specified location, or 0 if the value cannot be converted.
 */
short duckdb_value_int16 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The int32_t value at the specified location, or 0 if the value cannot be converted.
 */
int duckdb_value_int32 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The int64_t value at the specified location, or 0 if the value cannot be converted.
 */
long duckdb_value_int64 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The duckdb_hugeint value at the specified location, or 0 if the value cannot be converted.
 */
duckdb_hugeint duckdb_value_hugeint (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The uint8_t value at the specified location, or 0 if the value cannot be converted.
 */
ubyte duckdb_value_uint8 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The uint16_t value at the specified location, or 0 if the value cannot be converted.
 */
ushort duckdb_value_uint16 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The uint32_t value at the specified location, or 0 if the value cannot be converted.
 */
uint duckdb_value_uint32 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The uint64_t value at the specified location, or 0 if the value cannot be converted.
 */
ulong duckdb_value_uint64 (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The float value at the specified location, or 0 if the value cannot be converted.
 */
float duckdb_value_float (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The double value at the specified location, or 0 if the value cannot be converted.
 */
double duckdb_value_double (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The duckdb_date value at the specified location, or 0 if the value cannot be converted.
 */
duckdb_date duckdb_value_date (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The duckdb_time value at the specified location, or 0 if the value cannot be converted.
 */
duckdb_time duckdb_value_time (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The duckdb_timestamp value at the specified location, or 0 if the value cannot be converted.
 */
duckdb_timestamp duckdb_value_timestamp (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: The duckdb_interval value at the specified location, or 0 if the value cannot be converted.
 */
duckdb_interval duckdb_value_interval (duckdb_result* result, idx_t col, idx_t row);

/*!
* returns: The char* value at the specified location, or nullptr if the value cannot be converted.
The result must be freed with `duckdb_free`.
*/
char* duckdb_value_varchar (duckdb_result* result, idx_t col, idx_t row);

/*!
* returns: The char* value at the specified location. ONLY works on VARCHAR columns and does not auto-cast.
If the column is NOT a VARCHAR column this function will return NULL.

The result must NOT be freed.
*/
char* duckdb_value_varchar_internal (duckdb_result* result, idx_t col, idx_t row);

/*!
* returns: The duckdb_blob value at the specified location. Returns a blob with blob.data set to nullptr if the
value cannot be converted. The resulting "blob.data" must be freed with `duckdb_free.`
*/
duckdb_blob duckdb_value_blob (duckdb_result* result, idx_t col, idx_t row);

/*!
 * returns: Returns true if the value at the specified index is NULL, and false otherwise.
 */
bool duckdb_value_is_null (duckdb_result* result, idx_t col, idx_t row);

//===--------------------------------------------------------------------===//
// Helpers
//===--------------------------------------------------------------------===//
/*!
Allocate `size` bytes of memory using the duckdb internal malloc function. Any memory allocated in this manner
should be freed using `duckdb_free`.

* size: The number of bytes to allocate.
* returns: A pointer to the allocated memory region.
*/
void* duckdb_malloc (size_t size);

/*!
Free a value returned from `duckdb_malloc`, `duckdb_value_varchar` or `duckdb_value_blob`.

* ptr: The memory region to de-allocate.
*/
void duckdb_free (void* ptr);

//===--------------------------------------------------------------------===//
// Date/Time/Timestamp Helpers
//===--------------------------------------------------------------------===//
/*!
Decompose a `duckdb_date` object into year, month and date (stored as `duckdb_date_struct`).

* date: The date object, as obtained from a `DUCKDB_TYPE_DATE` column.
* returns: The `duckdb_date_struct` with the decomposed elements.
*/
duckdb_date_struct duckdb_from_date (duckdb_date date);

/*!
Re-compose a `duckdb_date` from year, month and date (`duckdb_date_struct`).

* date: The year, month and date stored in a `duckdb_date_struct`.
* returns: The `duckdb_date` element.
*/
duckdb_date duckdb_to_date (duckdb_date_struct date);

/*!
Decompose a `duckdb_time` object into hour, minute, second and microsecond (stored as `duckdb_time_struct`).

* time: The time object, as obtained from a `DUCKDB_TYPE_TIME` column.
* returns: The `duckdb_time_struct` with the decomposed elements.
*/
duckdb_time_struct duckdb_from_time (duckdb_time time);

/*!
Re-compose a `duckdb_time` from hour, minute, second and microsecond (`duckdb_time_struct`).

* time: The hour, minute, second and microsecond in a `duckdb_time_struct`.
* returns: The `duckdb_time` element.
*/
duckdb_time duckdb_to_time (duckdb_time_struct time);

/*!
Decompose a `duckdb_timestamp` object into a `duckdb_timestamp_struct`.

* ts: The ts object, as obtained from a `DUCKDB_TYPE_TIMESTAMP` column.
* returns: The `duckdb_timestamp_struct` with the decomposed elements.
*/
duckdb_timestamp_struct duckdb_from_timestamp (duckdb_timestamp ts);

/*!
Re-compose a `duckdb_timestamp` from a duckdb_timestamp_struct.

* ts: The de-composed elements in a `duckdb_timestamp_struct`.
* returns: The `duckdb_timestamp` element.
*/
duckdb_timestamp duckdb_to_timestamp (duckdb_timestamp_struct ts);

//===--------------------------------------------------------------------===//
// Hugeint Helpers
//===--------------------------------------------------------------------===//
/*!
Converts a duckdb_hugeint object (as obtained from a `DUCKDB_TYPE_HUGEINT` column) into a double.

* val: The hugeint value.
* returns: The converted `double` element.
*/
double duckdb_hugeint_to_double (duckdb_hugeint val);

/*!
Converts a double value to a duckdb_hugeint object.

If the conversion fails because the double value is too big the result will be 0.

* val: The double value.
* returns: The converted `duckdb_hugeint` element.
*/
duckdb_hugeint duckdb_double_to_hugeint (double val);

//===--------------------------------------------------------------------===//
// Prepared Statements
//===--------------------------------------------------------------------===//
// A prepared statement is a parameterized query that allows you to bind parameters to it.
// * This is useful to easily supply parameters to functions and avoid SQL injection attacks.
// * This is useful to speed up queries that you will execute several times with different parameters.
// Because the query will only be parsed, bound, optimized and planned once during the prepare stage,
// rather than once per execution.
// For example:
//   SELECT * FROM tbl WHERE id=?
// Or a query with multiple parameters:
//   SELECT * FROM tbl WHERE id=$1 OR name=$2

/*!
Create a prepared statement object from a query.

Note that after calling `duckdb_prepare`, the prepared statement should always be destroyed using
`duckdb_destroy_prepare`, even if the prepare fails.

If the prepare fails, `duckdb_prepare_error` can be called to obtain the reason why the prepare failed.

* connection: The connection object
* query: The SQL query to prepare
* out_prepared_statement: The resulting prepared statement object
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_prepare (
    duckdb_connection connection,
    const(char)* query,
    duckdb_prepared_statement* out_prepared_statement);

/*!
Closes the prepared statement and de-allocates all memory allocated for that connection.

* prepared_statement: The prepared statement to destroy.
*/
void duckdb_destroy_prepare (duckdb_prepared_statement* prepared_statement);

/*!
Returns the error message associated with the given prepared statement.
If the prepared statement has no error message, this returns `nullptr` instead.

The error message should not be freed. It will be de-allocated when `duckdb_destroy_prepare` is called.

* prepared_statement: The prepared statement to obtain the error from.
* returns: The error message, or `nullptr` if there is none.
*/
const(char)* duckdb_prepare_error (duckdb_prepared_statement prepared_statement);

/*!
Returns the number of parameters that can be provided to the given prepared statement.

Returns 0 if the query was not successfully prepared.

* prepared_statement: The prepared statement to obtain the number of parameters for.
*/
idx_t duckdb_nparams (duckdb_prepared_statement prepared_statement);

/*!
Returns the parameter type for the parameter at the given index.

Returns `DUCKDB_TYPE_INVALID` if the parameter index is out of range or the statement was not successfully prepared.

* prepared_statement: The prepared statement.
* param_idx: The parameter index.
* returns: The parameter type
*/
duckdb_type duckdb_param_type (duckdb_prepared_statement prepared_statement, idx_t param_idx);

/*!
Binds a bool value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_boolean (duckdb_prepared_statement prepared_statement, idx_t param_idx, bool val);

/*!
Binds an int8_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_int8 (duckdb_prepared_statement prepared_statement, idx_t param_idx, byte val);

/*!
Binds an int16_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_int16 (duckdb_prepared_statement prepared_statement, idx_t param_idx, short val);

/*!
Binds an int32_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_int32 (duckdb_prepared_statement prepared_statement, idx_t param_idx, int val);

/*!
Binds an int64_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_int64 (duckdb_prepared_statement prepared_statement, idx_t param_idx, long val);

/*!
Binds an duckdb_hugeint value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_hugeint (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    duckdb_hugeint val);

/*!
Binds an uint8_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_uint8 (duckdb_prepared_statement prepared_statement, idx_t param_idx, ubyte val);

/*!
Binds an uint16_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_uint16 (duckdb_prepared_statement prepared_statement, idx_t param_idx, ushort val);

/*!
Binds an uint32_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_uint32 (duckdb_prepared_statement prepared_statement, idx_t param_idx, uint val);

/*!
Binds an uint64_t value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_uint64 (duckdb_prepared_statement prepared_statement, idx_t param_idx, ulong val);

/*!
Binds an float value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_float (duckdb_prepared_statement prepared_statement, idx_t param_idx, float val);

/*!
Binds an double value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_double (duckdb_prepared_statement prepared_statement, idx_t param_idx, double val);

/*!
Binds a duckdb_date value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_date (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    duckdb_date val);

/*!
Binds a duckdb_time value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_time (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    duckdb_time val);

/*!
Binds a duckdb_timestamp value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_timestamp (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    duckdb_timestamp val);

/*!
Binds a duckdb_interval value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_interval (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    duckdb_interval val);

/*!
Binds a null-terminated varchar value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_varchar (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    const(char)* val);

/*!
Binds a varchar value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_varchar_length (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    const(char)* val,
    idx_t length);

/*!
Binds a blob value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_blob (
    duckdb_prepared_statement prepared_statement,
    idx_t param_idx,
    const(void)* data,
    idx_t length);

/*!
Binds a NULL value to the prepared statement at the specified index.
*/
duckdb_state duckdb_bind_null (duckdb_prepared_statement prepared_statement, idx_t param_idx);

/*!
Executes the prepared statement with the given bound parameters, and returns a materialized query result.

This method can be called multiple times for each prepared statement, and the parameters can be modified
between calls to this function.

* prepared_statement: The prepared statement to execute.
* out_result: The query result.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_execute_prepared (
    duckdb_prepared_statement prepared_statement,
    duckdb_result* out_result);

/*!
Executes the prepared statement with the given bound parameters, and returns an arrow query result.

* prepared_statement: The prepared statement to execute.
* out_result: The query result.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_execute_prepared_arrow (
    duckdb_prepared_statement prepared_statement,
    duckdb_arrow* out_result);

//===--------------------------------------------------------------------===//
// Appender
//===--------------------------------------------------------------------===//

// Appenders are the most efficient way of loading data into DuckDB from within the C interface, and are recommended for
// fast data loading. The appender is much faster than using prepared statements or individual `INSERT INTO` statements.

// Appends are made in row-wise format. For every column, a `duckdb_append_[type]` call should be made, after which
// the row should be finished by calling `duckdb_appender_end_row`. After all rows have been appended,
// `duckdb_appender_destroy` should be used to finalize the appender and clean up the resulting memory.

// Note that `duckdb_appender_destroy` should always be called on the resulting appender, even if the function returns
// `DuckDBError`.

/*!
Creates an appender object.

* connection: The connection context to create the appender in.
* schema: The schema of the table to append to, or `nullptr` for the default schema.
* table: The table name to append to.
* out_appender: The resulting appender object.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_appender_create (
    duckdb_connection connection,
    const(char)* schema,
    const(char)* table,
    duckdb_appender* out_appender);

/*!
Returns the error message associated with the given appender.
If the appender has no error message, this returns `nullptr` instead.

The error message should not be freed. It will be de-allocated when `duckdb_appender_destroy` is called.

* appender: The appender to get the error from.
* returns: The error message, or `nullptr` if there is none.
*/
const(char)* duckdb_appender_error (duckdb_appender appender);

/*!
Flush the appender to the table, forcing the cache of the appender to be cleared and the data to be appended to the
base table.

This should generally not be used unless you know what you are doing. Instead, call `duckdb_appender_destroy` when you
are done with the appender.

* appender: The appender to flush.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_appender_flush (duckdb_appender appender);

/*!
Close the appender, flushing all intermediate state in the appender to the table and closing it for further appends.

This is generally not necessary. Call `duckdb_appender_destroy` instead.

* appender: The appender to flush and close.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_appender_close (duckdb_appender appender);

/*!
Close the appender and destroy it. Flushing all intermediate state in the appender to the table, and de-allocating
all memory associated with the appender.

* appender: The appender to flush, close and destroy.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_appender_destroy (duckdb_appender* appender);

/*!
A nop function, provided for backwards compatibility reasons. Does nothing. Only `duckdb_appender_end_row` is required.
*/
duckdb_state duckdb_appender_begin_row (duckdb_appender appender);

/*!
Finish the current row of appends. After end_row is called, the next row can be appended.

* appender: The appender.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_appender_end_row (duckdb_appender appender);

/*!
Append a bool value to the appender.
*/
duckdb_state duckdb_append_bool (duckdb_appender appender, bool value);

/*!
Append an int8_t value to the appender.
*/
duckdb_state duckdb_append_int8 (duckdb_appender appender, byte value);
/*!
Append an int16_t value to the appender.
*/
duckdb_state duckdb_append_int16 (duckdb_appender appender, short value);
/*!
Append an int32_t value to the appender.
*/
duckdb_state duckdb_append_int32 (duckdb_appender appender, int value);
/*!
Append an int64_t value to the appender.
*/
duckdb_state duckdb_append_int64 (duckdb_appender appender, long value);
/*!
Append a duckdb_hugeint value to the appender.
*/
duckdb_state duckdb_append_hugeint (duckdb_appender appender, duckdb_hugeint value);

/*!
Append a uint8_t value to the appender.
*/
duckdb_state duckdb_append_uint8 (duckdb_appender appender, ubyte value);
/*!
Append a uint16_t value to the appender.
*/
duckdb_state duckdb_append_uint16 (duckdb_appender appender, ushort value);
/*!
Append a uint32_t value to the appender.
*/
duckdb_state duckdb_append_uint32 (duckdb_appender appender, uint value);
/*!
Append a uint64_t value to the appender.
*/
duckdb_state duckdb_append_uint64 (duckdb_appender appender, ulong value);

/*!
Append a float value to the appender.
*/
duckdb_state duckdb_append_float (duckdb_appender appender, float value);
/*!
Append a double value to the appender.
*/
duckdb_state duckdb_append_double (duckdb_appender appender, double value);

/*!
Append a duckdb_date value to the appender.
*/
duckdb_state duckdb_append_date (duckdb_appender appender, duckdb_date value);
/*!
Append a duckdb_time value to the appender.
*/
duckdb_state duckdb_append_time (duckdb_appender appender, duckdb_time value);
/*!
Append a duckdb_timestamp value to the appender.
*/
duckdb_state duckdb_append_timestamp (duckdb_appender appender, duckdb_timestamp value);
/*!
Append a duckdb_interval value to the appender.
*/
duckdb_state duckdb_append_interval (duckdb_appender appender, duckdb_interval value);

/*!
Append a varchar value to the appender.
*/
duckdb_state duckdb_append_varchar (duckdb_appender appender, const(char)* val);
/*!
Append a varchar value to the appender.
*/
duckdb_state duckdb_append_varchar_length (duckdb_appender appender, const(char)* val, idx_t length);
/*!
Append a blob value to the appender.
*/
duckdb_state duckdb_append_blob (duckdb_appender appender, const(void)* data, idx_t length);
/*!
Append a NULL value to the appender (of any type).
*/
duckdb_state duckdb_append_null (duckdb_appender appender);

//===--------------------------------------------------------------------===//
// Arrow Interface
//===--------------------------------------------------------------------===//
/*!
Executes a SQL query within a connection and stores the full (materialized) result in an arrow structure.
If the query fails to execute, DuckDBError is returned and the error message can be retrieved by calling
`duckdb_query_arrow_error`.

Note that after running `duckdb_query_arrow`, `duckdb_destroy_arrow` must be called on the result object even if the
query fails, otherwise the error stored within the result will not be freed correctly.

* connection: The connection to perform the query in.
* query: The SQL query to run.
* out_result: The query result.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_query_arrow (duckdb_connection connection, const(char)* query, duckdb_arrow* out_result);

/*!
Fetch the internal arrow schema from the arrow result.

* result: The result to fetch the schema from.
* out_schema: The output schema.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_query_arrow_schema (duckdb_arrow result, duckdb_arrow_schema* out_schema);

/*!
Fetch an internal arrow array from the arrow result.

This function can be called multiple time to get next chunks, which will free the previous out_array.
So consume the out_array before calling this function again.

* result: The result to fetch the array from.
* out_array: The output array.
* returns: `DuckDBSuccess` on success or `DuckDBError` on failure.
*/
duckdb_state duckdb_query_arrow_array (duckdb_arrow result, duckdb_arrow_array* out_array);

/*!
Returns the number of columns present in a the arrow result object.

* result: The result object.
* returns: The number of columns present in the result object.
*/
idx_t duckdb_arrow_column_count (duckdb_arrow result);

/*!
Returns the number of rows present in a the arrow result object.

* result: The result object.
* returns: The number of rows present in the result object.
*/
idx_t duckdb_arrow_row_count (duckdb_arrow result);

/*!
Returns the number of rows changed by the query stored in the arrow result. This is relevant only for
INSERT/UPDATE/DELETE queries. For other queries the rows_changed will be 0.

* result: The result object.
* returns: The number of rows changed.
*/
idx_t duckdb_arrow_rows_changed (duckdb_arrow result);

/*!
Returns the error message contained within the result. The error is only set if `duckdb_query_arrow` returns
`DuckDBError`.

The error message should not be freed. It will be de-allocated when `duckdb_destroy_arrow` is called.

* result: The result object to fetch the nullmask from.
* returns: The error of the result.
*/
const(char)* duckdb_query_arrow_error (duckdb_arrow result);

/*!
Closes the result and de-allocates all memory allocated for the arrow result.

* result: The result to destroy.
*/
void duckdb_destroy_arrow (duckdb_arrow* result);


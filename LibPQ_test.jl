using LibPQ, Tables

database = "probeapp"
user = "probeapp"
host = "127.0.0.1"
port = "5432"
password = "1234"

conn = LibPQ.Connection("host=$(host) port=$(port) dbname=$(database) user=$(user) password=$(password)"; throw_error=true)
result = execute(conn, "SELECT * FROM ProbeResultcar00000000000000000014885220135270514525")
data = columntable(result)

# # the same but with parameters
# result = execute(conn, "SELECT typname FROM pg_type WHERE oid = \$1", ["16"])
# data = columntable(result)

# # the same but asynchronously
# async_result = async_execute(conn, "SELECT typname FROM pg_type WHERE oid = \$1", ["16"])
# # do other things
# result = fetch(async_result)
# data = columntable(result)
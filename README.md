# Substreams Sink ClickHouse Showcase

This repository provides a Docker image that runs a ClickHouse Server and also contains the `substreams-sink-sql` binary, to showcase how to use the `substreams-sink-sql from-proto`. We provide a simple example of a Substreams package that produces data ready for use with a ClickHouse database.

#### Don't miss the deep dive: [Deep dive](./DEEP_DIVE.md)

### Building the image

``` shell script
 docker build -t substreams-sink-clickhouse-showcase:latest .
 ```

### Running a ClickHouse server

``` shell script
docker run --rm -it \
    -p 8123:8123 \
    -p 9000:9000 \
    -p 9009:9009 \
    --name clickehouse-showcase \
    substreams-sink-clickhouse-showcase:latest
```

### Open a session to the ClickHouse server with the native client
``` shell
docker exec -it clickehouse-showcase clickhouse-client --host 127.0.0.1
```

Security note: unauthenticated access is convenient for local development only. Do not expose this container to untrusted networks without adding proper authentication.

# Using substreams-sink-sql inside the container

Code for the Substreams example used can be found here: [usdc_transfers](substreams/usdc_transfers).

### Provide your Substreams API Key
Before running `substreams-sink-sql`, you must provide your Substreams `API KEY` via the `SUBSTREAMS_API_KEY` environment variable.

- If you don't have a `API KEY` yet, you can get one from [The Graph Market](https://thegraph.market/dashboard).
- On your host shell, export your token (replace XXX with your token):
```shell
export SUBSTREAMS_API_KEY=XXX
```

### Run the USDC transfers Substreams
Once ClickHouse is running, you can execute `substreams-sink-sql` inside of it. The command below will run the USDC transfers Substreams using the provided package and write to a ClickHouse database named `transfers`:

``` shell
docker exec -it \
  --env SUBSTREAMS_API_KEY="$SUBSTREAMS_API_KEY" \
  clickehouse-showcase bash -lc \
  'substreams-sink-sql from-proto \
  "clickhouse://127.0.0.1:9000/transfers?secure=false" \
  "https://github.com/streamingfast/substreams-sink-clickhouse-showcase/releases/download/v0.1.0/usdc-transfers-v0.1.0.spkg" \
  map_transfer \
  --network eth-mainnet -t 0  --block-batch-size 1000 --bytes-encoding 0xhex'
```

Notes:
- The command runs inside the container; `127.0.0.1:9000` refers to the ClickHouse server running in the same container.
- You can also set the token at container start for all execs: `docker run -e SUBSTREAMS_API_KEY=XXX ... substreams-sink-clickhouse-showcase:latest`.

## Query data within your ClickHouse server

To run queries, `exec` into the container and use the native `clickhouse-client`. For interactive usage, you can open the client with:

``` shell
docker exec -it clickehouse-showcase clickhouse-client --host 127.0.0.1
```



``` sql
SELECT 
    toYYYYMM(_block_timestamp_) AS month,
    sum(amount)                 AS volume,
    count()                     AS transfer_count
FROM transfers.transfers
WHERE _deleted_ = 0
GROUP BY month
ORDER BY month desc;
```

## Next: [Deep dive](./DEEP_DIVE.md)

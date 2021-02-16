# Benchmarking
Following the benchmark from the [cockroachdb docs](https://www.cockroachlabs.com/docs/v20.2/performance-benchmarking-with-tpcc-small).

## Running the benchmark
On the benchmark VM, run the following:

```
$ wget https://edge-binaries.cockroachdb.com/cockroach/workload.LATEST -O workload; chmod 755 workload
$ ./workload init tpcc --warehouses 100 "postgres://root@10.3.0.2:26257?sslmode=disable"

```
This will download the required data and insert the tables into the cockroach cluster.

To execute the benchmark, run:
```
./workload run tpcc \
--warehouses 100 \
--ramp 1m \
--duration 30m \
--histograms benchmark_results	\
 postgres://root@10.3.0.1:26257?sslmode=disable postgres://root@10.3.0.2:26257?sslmode=disable postgres://root@10.3.0.3:26257?sslmode=disable postgres://root@10.3.0.4:26257?sslmode=disable postgres://root@10.3.0.5:26257?sslmode=disable postgres://root@10.3.0.6:26257?sslmode=disable postgres://root@10.3.0.7:26257?sslmode=disable postgres://root@10.3.0.8:26257?sslmode=disable postgres://root@10.3.0.9:26257?sslmode=disable
```

For benchmark results, see respective folders.
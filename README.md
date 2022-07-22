# Envoy Failover Simulator

This project is useful for experimenting with the interactions between Envoy's
[aggregate
clusters](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/aggregate_cluster)
and [outlier
detection](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/outlier) for failover.

## Background

This starts an Envoy proxy with an aggregate cluster that looks like the following:
```yaml
name: cluster
connect_timeout: 0.25s
lb_policy: CLUSTER_PROVIDED
cluster_type:
  name: envoy.clusters.aggregate
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.clusters.aggregate.v3.ClusterConfig
    clusters:
    - cluster1
    - cluster2
```

It starts a simple Go server that returns `<CLUSTER_NAME> - <'success' |
'fail'>` for `cluster1` and `cluster2`. `cluster1` and `cluster2` look like the following:

```yaml
name: clusterX
type: STRICT_DNS
lb_policy: ROUND_ROBIN
outlier_detection: {}
load_assignment:
  cluster_name: clusterX
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: localhost
            port_value: 8000
```

Before running the experiment, the server for `cluster1` is configured to
always return a 500 status code with `curl 'http://localhost:8000/status?value=fail'`.

## Experiments

### Default Everything

Running `sh ./run.sh` returns results that look like the following:

```
1 | 0 seconds | 5 requests
2 | 38 seconds | 1868 requests
1 | 1 seconds | 53 requests
2 | 69 seconds | 3275 requests
1 | 1 seconds | 52 requests
2 | 99 seconds | 4623 requests
1 | 1 seconds | 52 requests
2 | 91 seconds | 4254 requests
```

Since there is only one endpoint for each cluster, requests are only sent to a
single cluster at a time.

Column meanings:
1. Cluster number
2. Duration in seconds
3. Number of requests


Explanation:
1. It initially takes 5 requests (`consecutive_5xx`'s default value) to initially eject `cluster1`.
2. `cluster1` is ejected for 38 seconds (`base_ejection_time` defaults to 30 seconds + `interval` of ejection analysis sweeps is 10 seconds).
3. `cluster1` receives 53 requests (`failure_percentage_request_volume` defaults to 50)
4. `cluster1` is ejected for 69 seconds (`base_ejection_time` defaults to 30 seconds * number of ejections)
5. `cluster1` receives 52 requests (`failure_percentage_request_volume` defaults to 50)
6. `cluster1` is ejected for 99 seconds (`base_ejection_time` defaults to 30 seconds * number of ejections)
7. `cluster1` receives 52 requests (`failure_percentage_request_volume` defaults to 50)
8. `cluster1` is ejected for 91 seconds (`base_ejection_time` defaults to 30 seconds * number of ejections). Note this is truncated by only running for 5 minutes.

`cluster1` will keep getting ejected until ejection times max out at `max_ejection_time` (300 seconds)


### Five Retries

This is the same experiment as above, but the route is updated to retry each
`5xx` error five times. Note that `5xx` errors also include TCP errors.

```
match:
  prefix: "/"
route:
  cluster: cluster
  retry_policy:
    num_retries: 5
    retry_on: 5xx
```

Results:
```
1 | 0 seconds | 0 requests
2 | 38 seconds | 1823 requests
1 | 1 seconds | 3 requests
2 | 70 seconds | 3543 requests
1 | 0 seconds | 3 requests
2 | 100 seconds | 5157 requests
1 | 0 seconds | 3 requests
2 | 91 seconds | 5079 requests
```

Note that this results in only 3 requests being made to `cluster1` between ejections.

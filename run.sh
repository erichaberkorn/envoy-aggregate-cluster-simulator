#! /bin/sh

killall server envoy
(cd server && go build .)
CLUSTER_NAME=cluster1 SERVER_PORT=8000 PRIORITY=0 ./server/server &
CLUSTER_NAME=cluster1 SERVER_PORT=8001 PRIORITY=0 ./server/server &
CLUSTER_NAME=cluster1 SERVER_PORT=8002 PRIORITY=0 ./server/server &
CLUSTER_NAME=cluster1 SERVER_PORT=8003 PRIORITY=1 ./server/server &
CLUSTER_NAME=cluster1 SERVER_PORT=8004 PRIORITY=1 ./server/server &
CLUSTER_NAME=cluster1 SERVER_PORT=8005 PRIORITY=1 ./server/server &
CLUSTER_NAME=cluster2 SERVER_PORT=9000 PRIORITY=1 ./server/server &

envoy -c envoy-config.yaml -l critical &

sleep 1

# curl 'http://localhost:8000/status?value=fail'
# curl 'http://localhost:8001/status?value=fail'
# curl 'http://localhost:8002/status?value=fail'
# curl 'http://localhost:8003/status?value=fail'
# curl 'http://localhost:8004/status?value=fail'
# curl 'http://localhost:9000/status?value=fail'

end=$((SECONDS+300))

t=$((SECONDS))
requests="0"
previous_cluster="1"
while [ $SECONDS -lt $end ]; do
  curl localhost:8080
done

pkill -P $$

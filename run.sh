#! /bin/sh

(cd server && go build .)
CLUSTER_NAME=cluster1 SERVER_PORT=8000 ./server/server &
CLUSTER_NAME=cluster2 SERVER_PORT=9000 ./server/server &

envoy -c envoy-config.yaml -l critical &

sleep 2

curl 'http://localhost:8000/status?value=fail'

end=$((SECONDS+300))

t=$((SECONDS))
requests="0"
previous_cluster="1"
while [ $SECONDS -lt $end ]; do
  result=$(curl --silent localhost:8080)
  # echo $result
  if [[ "$result" == "cluster1"* ]]; then
    cluster="1"
  else
    cluster="2"
  fi

  if [[ $cluster -ne $previous_cluster ]]; then
    diff=$((SECONDS-t))
    echo "$previous_cluster | $diff seconds | $requests requests"
    t=$((SECONDS))
    requests="1"
    previous_cluster="$cluster"
  else
    requests=$((requests + 1))
  fi
done

diff=$((SECONDS-t))
echo "$cluster | $diff seconds | $requests requests"

pkill -P $$

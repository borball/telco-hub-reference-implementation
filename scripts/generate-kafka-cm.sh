#!/bin/bash

set -e

kafka_namespace="amq-streams"
kafka_instance="spoke-logs"

#check if kafka route exists
if ! oc get route ${kafka_instance}-kafka-bootstrap -n $kafka_namespace >/dev/null 2>&1; then
    echo "ERROR: Route '${kafka_instance}-kafka-bootstrap' not found in namespace '$kafka_namespace'" >&2
    echo "Please check if you are connected to the correct cluster" >&2
    exit 1
fi

kafka_url="$(oc get route ${kafka_instance}-kafka-bootstrap -n $kafka_namespace -o jsonpath='{.spec.host}')"
kafka_broker_cert="$(oc get secret ${kafka_instance}-kafka-brokers -n $kafka_namespace -o jsonpath='{.data.spoke-logs-kafka-0\.crt}' | base64 -d)"
cluster_ca_cert="$(oc get secret ${kafka_instance}-cluster-ca-cert -n $kafka_namespace -o jsonpath='{.data.ca\.crt}' | base64 -d)"

echo "Add configmap below to the global-config.yaml of your target hub cluster in the git repository."
echo "Typical location is: /hubs/<hub-name>/resources/global-config.yaml"
echo ""
cat << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-logging-kafka
  namespace: ztp-vdu    
data:
  # dont encode values
  topic: $kafka_instance
  url: $kafka_url
  caCrt: |
$(echo "$kafka_broker_cert" | sed 's/^/    /')
$(echo "$cluster_ca_cert" | sed 's/^/    /')
EOF

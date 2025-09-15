#!/bin/bash
# script to create secret required by cluster-logging on hub cluster

#check if necessary tools are installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed."
  exit 1
fi


if ! command -v oc &> /dev/null; then
  echo "Error: oc is not installed."
  exit 1
fi

kafka_namespace="amq-streams"
kafka_instance="spoke-logs"

#check if kafka route exists
if ! oc get route ${kafka_instance}-kafka-bootstrap -n $kafka_namespace >/dev/null 2>&1; then
    echo "ERROR: Route '${kafka_instance}-kafka-bootstrap' not found in namespace '$kafka_namespace'" >&2
    echo "Please check if you are connected to the correct cluster" >&2
    exit 1
fi

oc get secret -n $kafka_namespace $kafka_instance-user -o json | \
jq '{
  apiVersion: .apiVersion,
  kind: .kind,
  type: .type,
  metadata: {
    name: "cluster-logging-kafka-auth",
    namespace: "ztp-vdu"
  },
  data: .data | with_entries(select(.key | IN("user.crt", "user.key")))
}' | oc apply -f -

echo "Secret created successfully: cluster-logging-kafka-auth"

oc get secret cluster-logging-kafka-auth -n ztp-vdu -o yaml

#!/bin/bash

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Function to display usage
usage() {
    echo "Usage: $0 -p <pull-secret-file> -c <cluster> -n <node1,node2,node3> -u <bmc_username> -P <bmc_password>"
    echo "  -p: Path to pull secret JSON file"
    echo "  -c: Cluster name"
    echo "  -n: Comma-separated list of node names"
    echo "  -u: BMC username"
    echo "  -P: BMC password"
    exit 1
}

# Initialize variables
PULL_SECRET_FILE=""
CLUSTER=""
NODES=""
BMC_USERNAME=""
BMC_PASSWORD=""

# Parse command line arguments
while getopts "p:c:n:u:P:h" opt; do
    case $opt in
        p)
            PULL_SECRET_FILE="$OPTARG"
            ;;
        c)
            CLUSTER="$OPTARG"
            ;;
        n)
            NODES="$OPTARG"
            ;;
        u)
            BMC_USERNAME="$OPTARG"
            ;;
        P)
            BMC_PASSWORD="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PULL_SECRET_FILE" || -z "$CLUSTER" || -z "$NODES" || -z "$BMC_USERNAME" || -z "$BMC_PASSWORD" ]]; then
    echo "Error: All parameters are required."
    usage
fi

# Validate pull secret file exists
if [[ ! -f "$PULL_SECRET_FILE" ]]; then
    echo "Error: Pull secret file '$PULL_SECRET_FILE' not found."
    exit 1
fi

# Export variables for jinja2 templates
export cluster="$CLUSTER"
export bmc_username=$(echo -n "$BMC_USERNAME" | base64 -w 0)
export bmc_password=$(echo -n "$BMC_PASSWORD" | base64 -w 0)
export pull_secret=$(cat "$PULL_SECRET_FILE" | jq -c .)

# Create pull secret
echo "Creating pull secret for cluster: $CLUSTER"
jinja2 $BASEDIR/pull-secret.yaml.j2 | oc apply -f -

# Process nodes and create BMC secrets
IFS=',' read -ra NODE_ARRAY <<< "$NODES"
for node in "${NODE_ARRAY[@]}"; do
    # Trim whitespace
    node=$(echo "$node" | xargs)
    if [[ -n "$node" ]]; then
        echo "Creating BMC secret for node: $node"
        export node="$node"
        jinja2 $BASEDIR/bmc-secrets.yaml.j2 | oc apply -f -
    fi
done

echo "All secrets created successfully!"


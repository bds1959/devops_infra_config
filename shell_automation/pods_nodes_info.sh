#!/bin/bash
set -x
# Define variables
KUBECONFIG_PATH=('/home/b1959/.kube/config_qa_161' '/home/b1959/.kube/config_int_248')  # Path to the kubeconfig files
OUTPUT_FILE="report.csv"
DEBUG_FILE="debug.json"
 
# Initialize or clear the output file
> "$OUTPUT_FILE"
 
for config in "${KUBECONFIG_PATH[@]}"; do
    CLUSTER_NAME=$(basename "$config" | awk -F '_' '{print $2}' | tr '[:lower:]' '[:upper:]')
    echo "Processing cluster: $CLUSTER_NAME" >> $OUTPUT_FILE
    echo "GETTING PODS RESTART DETAILS FOR CLUSTER: $CLUSTER_NAME" >> $OUTPUT_FILE
    # Create CSV file and add headers
    echo "Namespace, Pod-Name, Container-Name, Restart-Count, Last-Restart-Time, CPU-Usage, Memory-Usage" >> $OUTPUT_FILE
 
    # Fetch all pods in JSON format and save to a debug file
    kubectl --kubeconfig="$config" get pods --all-namespaces -o json > $DEBUG_FILE
 
    # Print out the number of items fetched for debugging
    echo "Number of items fetched: $(jq '.items | length' $DEBUG_FILE)"
 
    # Process the JSON data to find pods that have restarted more than once
    jq -r '
        .items[] as $pod |
        $pod.status.containerStatuses[]? | select(
            .restartCount > 1 and
            (
                .lastState.terminated.finishedAt? and
                (.lastState.terminated.finishedAt | type == "string") and
                (.lastState.terminated.finishedAt | fromdateiso8601? // 0 > (now - 86400))
            )
        ) | [
            $pod.metadata.namespace,
            $pod.metadata.name,
            .name,
            .restartCount,
            (.lastState.terminated.finishedAt // "N/A")
        ] | @csv' $DEBUG_FILE >> $OUTPUT_FILE
 
    # Append CPU and memory usage
    kubectl --kubeconfig="$config" top pod --all-namespaces --containers | awk -v CLUSTER="$CLUSTER_NAME" 'BEGIN {FS=" "; OFS=","} {print $1,$2,$3,$4,$5,$6}' >> $OUTPUT_FILE
 
    echo "" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "GETTING NODE DETAILS FOR CLUSTER: $CLUSTER_NAME" >> $OUTPUT_FILE
    echo "--------------------------------------" >> $OUTPUT_FILE
    echo "Node-Name, Node-IP, Status, CPU-Usage, Memory-Usage, /var/lib/docker Disk Utilization" >> $OUTPUT_FILE
 
    # Get node details including CPU and memory usage
    kubectl --kubeconfig="$config" get nodes -o json | jq -r '
        .items[] | [
            .metadata.name,
            (.status.addresses[] | select(.type == "InternalIP") | .address // "N/A"),
            (.status.conditions[] | select(.type == "Ready") | .status // "Unknown")
        ] | @csv' >> $OUTPUT_FILE
 
    # Append CPU and memory usage for nodes
    kubectl --kubeconfig="$config" top nodes | awk 'BEGIN {FS=" "; OFS=","} {print $1,$2,$3,$4}' >> $OUTPUT_FILE
 
    # Append disk utilization for /var/lib/docker
    for node in $(kubectl --kubeconfig="$config" get nodes --no-headers -o custom-columns=":metadata.name"); do
        if [[ "$node" == "bcblrtkbnt11" || "$node" == "bcblrtkbnt12" || "$node" == "bcblrtkbnt13" || "$node" == "bcblrtkbnt14" || "$node" == "bcblrikbnt15" || "$node" == "bcblrtkbnt9" ]]; then
            NODE_IP=$(kubectl --kubeconfig="$config" get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
            DISK_USAGE=$(ssh bckbnt@"$NODE_IP" 'df -h /var/lib/docker | tail -n 1 | awk "{print \$5}"')
        else
            NODE_IP=$(kubectl --kubeconfig="$config" get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
            DISK_USAGE=$(ssh bdskbnt@"$NODE_IP" 'df -h /var/lib/docker | tail -n 1 | awk "{print \$5}"')
        fi
        echo "$node, $NODE_IP, $DISK_USAGE" >> "$OUTPUT_FILE"
    done
 
    echo "" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "GETTING PODS THAT ARE IN NON-RUNNING STATES AND INCLUDE STATUS FOR CLUSTER: $CLUSTER_NAME" >> $OUTPUT_FILE
    echo "-------------------------------------------------------------------" >> $OUTPUT_FILE
    echo "Namespace, Pod-Name, Node-Name, Status" >> $OUTPUT_FILE
    kubectl --kubeconfig="$config" get pods --all-namespaces -o json | jq -r '
        .items[] | select(
            .status.phase != "Running" or
            .status.containerStatuses[]?.state.waiting.reason == "CrashLoopBackOff" or
            .status.containerStatuses[]?.state.waiting.reason == "ContainerStatusUnknown"
        ) | [
            .metadata.namespace,
            .metadata.name,
            .spec.nodeName,
            (
                if .status.phase == "Pending" then "Pending" else
                if .status.phase == "Succeeded" then "Succeeded" else
                if .status.phase == "Failed" then "Failed" else
                .status.containerStatuses[]?.state.waiting.reason // "Unknown"
                end end end
            )
        ] | @csv' >> $OUTPUT_FILE
 
    echo "==================================================================================" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "Details of pods and nodes have been saved to $OUTPUT_FILE for cluster: $CLUSTER_NAME"
 
    rm -rf $DEBUG_FILE
done
 
# Send email with the report attached
EMAIL_RECIPIENTS="s.shahina@banyancloud.io"
EMAIL_SUBJECT="Cluster Report - $(date +'%B %d, %Y')"
EMAIL_BODY="Hello Team,\n\nPlease find attached the pod and nodes Report for the specified clusters. This report includes:\n\n1. **Pod Restart Details**: Information on pods that have restarted more than once in the last day.\n2. **Node Details**: Details about the nodes in the cluster including node name, IP, and status.\n3. **Non-Running Pods**: Details of pods that are in non-running states along with their status and node information.\n\nIf you have any questions or need further information, please feel free to reach out.\n\nBest regards,\n[DevOps team]."
 
echo "$EMAIL_BODY" | mailx -s "$EMAIL_SUBJECT" -a "/home/b1959/git/devops_infra_config/shell_automation/$OUTPUT_FILE" "$EMAIL_RECIPIENTS"
 
echo "Email sent to $EMAIL_RECIPIENTS with the report attached."
 
#rm -rf $OUTPUT_FILE
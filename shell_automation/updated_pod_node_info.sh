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
    echo "Namespace,Pod-Name,Container-Name,Restart-Count,Last-Restart-Time,Reason,Exit-Code,CPU(usage),Memory(usage)" >> $OUTPUT_FILE

    # Fetch all pods in JSON format and save to a debug file
    kubectl --kubeconfig="$config" get pods --all-namespaces -o json > $DEBUG_FILE

    # Fetch pod CPU and memory usage and store in a temporary file
    kubectl --kubeconfig="$config" top pods --all-namespaces | awk 'BEGIN {OFS=","} {print $1,$2,$3,$4}' > pod_metrics.tmp

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
            (.lastState.terminated.finishedAt // "N/A"),
            (.lastState.terminated.reason // "N/A"),
            (.lastState.terminated.exitCode // "N/A")
        ] | @csv' $DEBUG_FILE > pod_restarts.tmp

    while IFS=, read -r namespace pod_name container_name restart_count last_restart_time reason exit_code; do
        # Remove the double quotes from namespace and pod_name for the search
        namespace=$(echo "$namespace" | tr -d '"')
        pod_name=$(echo "$pod_name" | tr -d '"')

        # Extract pod CPU and memory usage for the matching namespace and pod name
        pod_cpu_memory=$(grep -E "^$namespace,$pod_name," pod_metrics.tmp | cut -d ',' -f 3,4)
        
        # Print debug information
        echo "print pod metrics: $namespace, $pod_name"

        # If CPU/memory info is found, append it, otherwise use N/A
        if [[ -n "$pod_cpu_memory" ]]; then
            echo "$namespace,$pod_name,$container_name,$restart_count,$last_restart_time,$reason,$exit_code,$pod_cpu_memory" >> "$OUTPUT_FILE"
        else
            echo "$namespace,$pod_name,$container_name,$restart_count,$last_restart_time,$reason,$exit_code,N/A,N/A" >> "$OUTPUT_FILE"
        fi
    done < pod_restarts.tmp

    echo "" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "GETTING NODE DETAILS FOR CLUSTER: $CLUSTER_NAME" >> $OUTPUT_FILE
    echo "--------------------------------------" >> $OUTPUT_FILE
    echo "Node-Name,Node-IP,Status,CPU(cores),Memory(usage),Disk-Usage(/var/lib/docker)" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE

    # Get node CPU and memory usage and store them in a temporary file
    kubectl --kubeconfig="$config" top nodes | awk 'BEGIN {FS=" "; OFS=","} {print $1,$2,$3}' > cpu_memory_usage.tmp

    # Append disk utilization for /var/lib/docker for each node
    for node in $(kubectl --kubeconfig="$config" get nodes --no-headers -o custom-columns=":metadata.name"); do
        NODE_IP=$(kubectl --kubeconfig="$config" get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
        
        # Get disk utilization
        if [[ "$node" == "bcblrtkbnt11" || "$node" == "bcblrtkbnt12" || "$node" == "bcblrtkbnt13" || "$node" == "bcblrtkbnt14" || "$node" == "bcblrikbnt15" || "$node" == "bcblrtkbnt9" ]]; then
            DISK_USAGE=$(ssh bckbnt@"$NODE_IP" 'df -h /var/lib/docker | tail -n 1 | awk "{print \$5}"')
        else
            DISK_USAGE=$(ssh bdskbnt@"$NODE_IP" 'df -h /var/lib/docker | tail -n 1 | awk "{print \$5}"')
        fi

        # Now we combine CPU, memory, and disk usage in one row
        CPU_MEMORY=$(grep "^$node" cpu_memory_usage.tmp)
        
        if [ -n "$CPU_MEMORY" ]; then
            echo "$node,$NODE_IP,$CPU_MEMORY,$DISK_USAGE" >> "$OUTPUT_FILE"
        else
            echo "$node,$NODE_IP,N/A,N/A,$DISK_USAGE" >> "$OUTPUT_FILE"
        fi
    done

    # Clean up the temporary files
    rm -f cpu_memory_usage.tmp pod_metrics.tmp pod_restarts.tmp

    echo "" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "GETTING PODS THAT ARE IN NON-RUNNING STATES AND INCLUDE STATUS FOR CLUSTER: $CLUSTER_NAME" >> $OUTPUT_FILE
    echo "-------------------------------------------------------------------" >> $OUTPUT_FILE
    echo "Namespace,Pod-Name,Node-Name,Status" >> $OUTPUT_FILE
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
EMAIL_RECIPIENTS="murali@banyancloud.io"
EMAIL_SUBJECT="Cluster Report - $(date +'%B %d, %Y')"
EMAIL_BODY="Hello Team,\n\nPlease find attached the pod and nodes Report for the specified clusters. This report includes:\n\n1. **Pod Restart Details**: Information on pods that have restarted more than once in the last day, along with CPU and memory utilization.\n2. **Node Details**: Details about the nodes in the cluster including node name, IP, CPU, memory, and disk usage.\n3. **Non-Running Pods**: Details of pods that are in non-running states along with their status and node information.\n\nIf you have any questions or need further information, please feel free to reach out.\n\nBest regards,\n[DevOps team]."

echo "$EMAIL_BODY" | mailx -s "$EMAIL_SUBJECT" -a "/home/b1959/git/devops_infra_config/shell_automation/$OUTPUT_FILE" "$EMAIL_RECIPIENTS"

echo "Email sent to $EMAIL_RECIPIENTS with the report attached."

#rm -rf $OUTPUT_FILE

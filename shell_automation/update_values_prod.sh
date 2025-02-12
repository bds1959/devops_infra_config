#!/bin/bash

# Search for all values-prod.yaml files in the current directory and subdirectories
for FILE in $(find ../../Titan_HelmCharts -type f -name "values-prod.yaml"); do

    # Check if the file exists
    if [[ -f "$FILE" ]]; then
        echo "Processing $FILE..."

        # Comment out the existing podSecurityContext and its fields, but place podSecurityContext: {} first
        sed -i '/podSecurityContext:/,/securityContext:/{
            /runAsUser:/ s/^/# /
            /fsGroup:/ s/^/# /
            /podSecurityContext:/ s/^/# podSecurityContext:/
        }' "$FILE"

        # Replace the first commented podSecurityContext with podSecurityContext: {}
        sed -i '0,/^# podSecurityContext:/s/^# podSecurityContext:.*/podSecurityContext: {}/' "$FILE"

        # Comment out the existing securityContext and its fields, but place securityContext: {} first
        sed -i '/securityContext:/,/capabilities:/{
            /allowPrivilegeEscalation:/ s/^/# /
            /readOnlyRootFilesystem:/ s/^/# /
            /runAsNonRoot:/ s/^/# /
            /securityContext:/ s/^/# securityContext:/
        }' "$FILE"

        # Replace the first commented securityContext with securityContext: {}
        sed -i '0,/^# securityContext:/s/^# securityContext:.*/securityContext: {}/' "$FILE"

        # Comment out 'capabilities' section and all nested fields
        sed -i '/capabilities:/,/^- ALL/{
            /capabilities:/ s/^/# /
            /drop:/ s/^/# /
            /- ALL/ s/^/# /
        }' "$FILE"

        echo "Successfully updated $FILE"
    else
        echo "$FILE does not exist."
    fi

done


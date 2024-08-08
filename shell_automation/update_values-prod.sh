#!/bin/bash

# Define the search and replacement patterns
search_pod_security="podSecurityContext: {}"
replace_pod_security="podSecurityContext:\n  runAsUser: 1000\n  fsGroup: 2000 "

search_security="securityContext: {}"
replace_security="securityContext:\n  allowPrivilegeEscalation: false\n  readOnlyRootFilesystem: true\n  runAsNonRoot: true\n  capabilities:\n    drop:\n      - ALL"

# Loop through all values.yaml files
for file in $(find /home/b1959/git/Titan_HelmCharts -name 'values-prod.yaml'); do
    # Replace podSecurityContext
    sed -i "s|$search_pod_security|$replace_pod_security|" "$file"
    
    # Replace securityContext
    sed -i "s|$search_security|$replace_security|" "$file"
    
    echo "Updated $file"
done


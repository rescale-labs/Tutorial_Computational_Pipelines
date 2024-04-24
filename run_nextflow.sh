#!/bin/bash

# Create Tags
create_tag() {
    local text="$1"
    curl -H "Authorization: Token ${RESCALE_API_KEY}" -H "Content-Type: application/json" "${RESCALE_API_BASE_URL}/api/v2/jobs/${RESCALE_JOB_ID}/tags/" -X POST -d "{ \"name\": \"${text}\" }"
}
create_tag "Computational_Pipeline"
create_tag "Study:${RUNNAME}"

# Save original directory
original_directory="$PWD"

# Add API key to Nextflow config
mkdir -p ~/.nextflow
echo -e "env {\n  RESCALE_CLUSTER_TOKEN = \"$RESCALE_API_KEY\"\n}" > ~/.nextflow/config
touch -d "2024-01-01T06:00:00" ~/.nextflow/config

# Find HPS and copy input files to HPS
NUM_HPS_DIRS=$(find / -maxdepth 1 -name "storage_?" -type d | wc -l)
HPS_DIR=$(find / -maxdepth 1 -name "storage_?" -type d)
export WORKDIR="${HPS_DIR}/${RUNNAME}"

if [ "$NUM_HPS_DIRS" -ne 1 ]; then
    echo "Error: HPS directory not found or not unique."
    exit 1
else
    echo "Using work directory $WORKDIR"
fi
mkdir -p "$WORKDIR"

# move script to bin directory, as required by nextflow
mkdir -p bin
mv suggest_hardware.py bin/

# Copy everything but .log files and hidden files to the work directory on the HPS.
# Do not copy files with unchanged checksum to preserve Nextflow resume logic.
rsync -rvv --checksum  --exclude='.*' --exclude '*.log' . "$WORKDIR"
cd "$WORKDIR" || exit

# temporary workaround for AWS
sudo chmod 755 /program/nextflow-alpha3-sxp/nextflow

# Run Nextflow
timestamp=$(date '+%Y-%m-%d_%H%M%S')
nextflow -log "nextflow_${timestamp}.log" run workflow.nf -resume -with-report "nextflow_execution_report_${timestamp}.html" -with-trace -with-timeline "nextflow_timeline_${timestamp}.html"

# Copy important results back to original directory
rsync -vv ./*.log ./*.html "$original_directory"
rsync -vv output/* "$original_directory"
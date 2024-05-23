#!/bin/bash

# Base directory where snapshots are stored
SNAPSHOT_BASE_DIR="/var/www/snapshots"
# Output file for the JSON data
OUTPUT_FILE="${SNAPSHOT_BASE_DIR}/chains.json"

echo '{ "chains": [' > $OUTPUT_FILE

FIRST_CHAIN=true
for CHAIN_DIR in ${SNAPSHOT_BASE_DIR}/*/; do

    if [ "$FIRST_CHAIN" = true ]; then
        FIRST_CHAIN=false
    else
        echo ',' >> $OUTPUT_FILE
    fi

    # Extract chain name from directory
    CHAIN_NAME=$(basename $CHAIN_DIR)
    echo '  { "name": "'$CHAIN_NAME'", "snapshots": [' >> $OUTPUT_FILE

    FIRST_SNAPSHOT=true
    for SNAPSHOT in ${CHAIN_DIR}/*.{tar.gz,tar.zst}; do
        if [ -e "$SNAPSHOT" ]; then

            if [ "$FIRST_SNAPSHOT" = true ]; then
                FIRST_SNAPSHOT=false
            else
                echo ',' >> $OUTPUT_FILE
            fi
            # Extract snapshot details
            SNAPSHOT_NAME=$(basename $SNAPSHOT)
            SNAPSHOT_DATE=$(stat --format='%y' $SNAPSHOT | cut -d'.' -f1)
            HEIGHT=$(echo $SNAPSHOT_NAME | sed 's/.*_height_\([0-9]*\).*/\1/')
            SNAPSHOT_SIZE=$(stat --format='%s' $SNAPSHOT)

            # Add snapshot details to JSON
            echo '    { "name": "'$CHAIN_NAME'", "snapshot": "'$SNAPSHOT_NAME'", "date": "'$SNAPSHOT_DATE'", "height": "'$HEIGHT'", "size": "'$SNAPSHOT_SIZE'" }' >> $OUTPUT_FILE
        fi
    done

    echo '  ] }' >> $OUTPUT_FILE
done

echo '] }' >> $OUTPUT_FILE

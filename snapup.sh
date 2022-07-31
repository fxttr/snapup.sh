#!/bin/sh

ENC=true
SSH=true
FULL=true
DATE=$(date +"%d-%m-%y")
NAME=$(hostname)

snap() {
    zfs snapshot $1@$DATE
}

snap_full() {
    zfs snapshot -r $SNAPUP_SOURCE_POOL@$DATE
}

send() {
    echo -n "Sending $1..."
    
    TRANSFORMED_DATASET_NAME=$(echo "$1" | sed -e 's/\//\_/g')
    zfs send $1 | ssh $SNAPUP_HOST pfexec zfs recv -F $SNAPUP_DESTINATION_POOL/"$NAME"_"$TRANSFORMED_DATASET_NAME"

    echo "done."
}

send_enc() {
    echo -n "Sending $1..."
    
    TRANSFORMED_DATASET_NAME=$(echo "$1" | sed -e 's/\//\_/g')    
    zfs send $1 | ssh $SNAPUP_HOST pfexec zfs recv -F -o encryption=on -o keyformat=raw -o keylocation=$SNAPUP_KEY $SNAPUP_DESTINATION_POOL/"$NAME"_"$TRANSFORMED_DATASET_NAME"

    echo "done."
}

if [ -z "$SNAPUP_KEY" ]; then
    echo "WARNING: Could not find SNAPUP_KEY. Disabling encryption.";
    ENC=false
fi

if [ -z "$SNAPUP_HOST" ]; then
    echo "ERROR: Could not find SNAPUP_HOST."
    echo "Please set SNAPUP_HOST."
    echo "If you use SSH, add a configured host to your SSH config."
    echo "Aborting."
    exit 1
fi

if [ -z "$SNAPUP_SOURCE_POOL" ]; then
    echo "WARNING: Could not determine which zpool you want to backup. Disabling full backups."
    echo "Please set SNAPUP_SOURCE_POOL if you want to make full backups."
    FULL=false
fi

if [ -z "$SNAPUP_DESTINATION_POOL" ]; then
    echo "ERROR: Could not determine which zpool you want to backup."
    echo "Please set SNAPUP_DESTINATION_POOL."
    echo "Aborting."
    exit 1
fi

if [ -z "$SNAPUP_DATASETS" ]; then
    if [ "$FULL" = false ]; then
	echo "You didn't set SNAPUP_SOURCE_POOL"
	echo "Can't taking a recursive snapshot."
	exit 1
    else
	echo "Taking recursive snapshot."
	snap_full
    fi
else
    for dataset in "$SNAPUP_DATASETS"; do
	snap $dataset
    done
fi

TAKEN_SNAPSHOTS=$(zfs list -t snap -o name | grep $DATE)

if [ "$ENC" = true ]; then
    for snapshot in $TAKEN_SNAPSHOTS; do
	send_enc $snapshot
    done
else
    for snapshot in $TAKEN_SNAPSHOTS; do
	send $snapshot
    done
fi

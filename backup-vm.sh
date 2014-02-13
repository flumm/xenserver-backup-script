#!/bin/bash

### Usage
if [ $# -lt 2 ]; then
	echo "Usage: " $(basename $0) " uuid-of-vm folder-to-export [--dryrun] " 1>&2
	exit 1
fi

UUID=$1
EXPORTPATH=$2
LEN=${#EXPORTPATH}-1

### Add trailing slash to export folder
if [ "${EXPORTPATH:LEN}" != "/" ]; then
	EXPORTPATH=$EXPORTPATH"/"
fi

TEMP=$(xe vm-list is-control-domain=false | grep -A1 $UUID)
if [ $? -ne 0 ]; then
	echo "UUID $UUID not found. Aborting"
	exit 1

else
	echo "UUID $UUID found."
	VMNAME=$(expr "$TEMP" : '.*\:\ \([a-zA-Z0-9\-\_\+\.]*\)')
	echo "Has the name: $VMNAME"
	if [ "$3" != "--dryrun" ]; then
		echo "Creating snapshot: \"$VMNAME\" "
		SNAPSHOTUUID=$(xe vm-snapshot uuid=$UUID new-name-label=$VMNAME)
		echo "Snapshot UUID: $SNAPSHOTUUID"
		echo "Converting Snapshot to VM"
		xe template-param-set is-a-template=false ha-always-run=false uuid=$SNAPSHOTUUID
		echo "Export to File: $EXPORTPATH$VMNAME.xva"
		if [ ! -d "$EXPORTPATH" ]; then
			echo "Creating directory $EXPORTPATH"
			mkdir -p "$EXPORTPATH"
		fi 
		xe vm-export vm=$SNAPSHOTUUID filename="$EXPORTPATH$VMNAME.xva"
		echo "Deleting Snapshot"
		xe vm-uninstall uuid=$SNAPSHOTUUID force=true
		echo "All done."
	else
		echo "This is a dryrun. Would have executed:"
		echo "xe vm-snapshot uuid=$UUID new-name-label=$VMNAME"
		echo "xe template-param-set is-a-template=false ha-always-run=false uuid=[SNAPSHOTUUID]"
		if [ ! -d "$EXPORTPATH" ]; then
			echo "mkdir -p \"$EXPORTPATH\""
		fi 
		echo "xe vm-export vm=[SNAPSHOTUUID] filename=\"$EXPORTPATH$VMNAME.xva\""
		echo "xe vm-uninstall uuid=[SNAPSHOTUUID] force=true"
	fi
fi
exit 0
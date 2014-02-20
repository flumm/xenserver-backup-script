#!/bin/bash

#
# Author: Dominik Csapak <dominik.csapak@gmail.com>
#

### Usage
usage(){
cat << EOF
usage: 

$0 -a [-e EXCLUDE_FILE] [-p EXPORT_PATH] [-d]
$0 -u UUID [-p EXPORT_PATH] [-d] 

OPTIONS:
-a                    Backup All VMs
-e EXCLUDE_FILE	      Exclude All VMs which names are in EXCLUDE_FILE
-u UUID               UUID of a single VM to Backup
-p EXPORT_PATH        Backups up VM(s) to EXPORT_PATH, default is current directory
-d                    Dryrun. Does not actually invoke any commands, for testing
EOF
}

ALL_VMS=0
EXCLUDE_FILE=
UUID=
UUIDS=
EXPORTPATH=
DRYRUN=0
NUMBER_OF_BACKUPS=3
EXCLUDEDVMS=""


while getopts "ade:p:u:" OPTION
do
	case $OPTION in 
		a)
			ALL_VMS=1
			if [ -n "$UUID" ]; then
				usage
				exit 1
			fi
			;;
		d)
			DRYRUN=1
			;;
		e)
			EXCLUDE_FILE=$OPTARG
			;;
		p)
			EXPORTPATH=$OPTARG
			LEN=${#EXPORTPATH}-1

			### Add trailing slash to export folder
			if [ "${EXPORTPATH:LEN}" != "/" ]; then
				EXPORTPATH=$EXPORTPATH"/"
			fi

			;;
		u)
			UUID=$OPTARG
			if [ "$ALL_VMS" -ne "0" ]; then
				usage
				exit 1
			fi
			;;
		\?)
			usage
			exit 1
			;;
	esac
done

backup-single-vm(){
	VMUUID=$1
	### Check if UUID exists
	TEMP=$(xe vm-list is-control-domain=false | grep -A1 $VMUUID)
	if [ $? -ne 0 ]; then
		echo "=============================================================="
		echo $(date +%d.%m.%Y\ %R:%S\ ) "UUID $VMUUID not found. Aborting"
		echo "=============================================================="
		return 1
	else
		echo "=============================================================="
		echo $(date +%d.%m.%Y\ %R:%S\ ) "UUID $VMUUID found."
		VMNAME=$(expr "$TEMP" : '.*\:\ \([a-zA-Z0-9\-\_\+\.\ \(\)\-]*\)')
		echo $(date +%d.%m.%Y\ %R:%S\ ) "Has the name: $VMNAME"
		if [[ $EXCLUDEDVMS =~ "$VMNAME," ]]; then
			echo "$VMNAME is in excluded list, not backing up"
		elif [ "$DRYRUN" -eq "0" ]; then
			echo $(date +%d.%m.%Y\ %R:%S\ ) "Creating snapshot: \"$VMNAME\" "
			SNAPSHOTUUID=$(xe vm-snapshot uuid=$VMUUID new-name-label="$VMNAME")
			echo $(date +%d.%m.%Y\ %R:%S\ ) "Snapshot UUID: $SNAPSHOTUUID"
			echo $(date +%d.%m.%Y\ %R:%S\ ) "Converting Snapshot to VM"
			xe template-param-set is-a-template=false ha-always-run=false uuid=$SNAPSHOTUUID
			echo $(date +%d.%m.%Y\ %R:%S\ ) "Export to File: $EXPORTPATH$VMNAME/$VMNAME.xva"
			if [ -n "$EXPORTPATH" ] && [ ! -d "$EXPORTPATH$VMNAME" ]; then
				echo $(date +%d.%m.%Y\ %R:%S\ ) "Creating directory $EXPORTPATH$VMNAME"
				mkdir -p $EXPORTPATH$VMNAME
			fi 
			xe vm-export vm=$SNAPSHOTUUID filename="$EXPORTPATH$VMNAME/$VMNAME.xva"
			echo $(date +%d.%m.%Y\ %R:%S\ ) "Deleting Snapshot"
			xe vm-uninstall uuid=$SNAPSHOTUUID force=true
			echo $(date +%d.%m.%Y\ %R:%S\ ) "All done."
		else
			echo $(date +%d.%m.%Y\ %R:%S\ ) "This is a dryrun. Would have executed:"
			echo $(date +%d.%m.%Y\ %R:%S\ ) "xe vm-snapshot uuid=$VMUUID new-name-label='$VMNAME'"
			echo $(date +%d.%m.%Y\ %R:%S\ ) "xe template-param-set is-a-template=false ha-always-run=false uuid=[SNAPSHOTUUID]"
			if [ -n "$EXPORTPATH" ] && [ ! -d "$EXPORTPATH$VMNAME" ]; then
				echo $(date +%d.%m.%Y\ %R:%S\ ) "mkdir -p \"$EXPORTPATH$VMNAME\""
			fi 
			echo $(date +%d.%m.%Y\ %R:%S\ ) "xe vm-export vm=[SNAPSHOTUUID] filename='$EXPORTPATH$VMNAME/$VMNAME.xva'"
			echo $(date +%d.%m.%Y\ %R:%S\ ) "xe vm-uninstall uuid=[SNAPSHOTUUID] force=true"
		fi
		echo "=============================================================="
	fi
}

get-all-vms(){
	UUIDS=
	TMP=$(xe vm-list is-control-domain=false | grep -i uuid)
#	TMP="uuid ( RO)           : 77b55200-67c7-4325-b3af-1874e4c4ef10\nuuid ( RO)           : 77b55201-67c7-4325-b3af-1874e4c4ef11\nuuid ( RO)           : 77b55202-67c7-4325-b3af-1874e4c4ef12\nuuid ( RO)           : 77b55203-67c7-4325-b3af-1874e4c4ef13\n"
	UUIDS=$(echo $TMP | sed 's/uuid[^\:]*\:\ //g')
}

if [ -z "$EXPORTPATH" ]; then
	EXPORTPATH="./"
fi

if [ -n "$UUID" ]; then
	backup-single-vm $UUID
elif [ "$ALL_VMS" -ne "0" ]; then
	get-all-vms
	if [ -n "$UUIDS" ]; then
		echo "-------------------------------------------------------------"
		echo "Found following UUIDS"
		for UUID in $UUIDS; do
			echo $UUID
		done
		echo "-------------------------------------------------------------"

		for UUID in $UUIDS; do
			backup-single-vm $UUID
		done
	else
		echo "Could not find any VMs."
	fi
else
	usage
	exit 1
fi

exit 0
xenserver-backup-script
=======================

Simple Shell Script based Backup for Xenserver VMs.

Tested with Xenserver 6.2.
Makes a Snapshot of Disk, converts the snapshot as vm and exports the vm to .xva file.
Makes one folder per VM and a folder per Backup
Keeps 3 Backups per default (look for Variable "NUMBER_OF_BACKUPS")

##### Installation:

Just copy it to your Xenserver 6.2 Installation and make it executable (chmod +x)

##### Usage:

Backup up multiple (or all) VMs

`./backup-vm.sh -a [-e EXCLUDE_FILE] [-p EXPORT_PATH] [-d]`

Backup up a single VM

`./backup-vm.sh -u UUID [-p EXPORT_PATH] [-d]`

##### Parameters:

Parameter | Description
--- | --- 
-u UUID |The UUID of the VM you wish to backup. You can get a list of them with. "xe vm-list is-control-domain=false".
-p EXPORT_PATH | The Folder you wish to back up your VM. Can be absolute or relative. Trailing slash will be added, so no filenames.
-d | If added, no actual commands are executed
-a | If added, all VMs are about to backup up
-e EXCLUDE_FILE | Defines the file which contains the name of the VMs wich you do not want backed up (one per line)

##### Restoring:

On the command line, run:

`xe vm-import filename=[path to .xva file]`


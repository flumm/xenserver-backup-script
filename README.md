xenserver-backup-script
=======================

Simple Shell Script based Backup for Xenserver VMs.

Tested with Xenserver 6.2.
Makes a Snapshot of Disk, converts the snapshot as vm and exports the vm to .xva file.

##### Installation:

Just copy it to your Xenserver 6.2 Installation and make it executable (chmod +x)

##### Usage:

`./backup-vm.sh uuid-of-vm folder-to-export [--dryrun]`

##### Parameters:

Parameter | Description
--- | --- 
uuid-of-vm |The UUID of the VM you wish to backup. You can get a list of them with. "xe vm-list is-control-domain=false".
folder-to-export | The Folder you wish to back up your VM. Can be absolute or relative. Trailing slash will be added, so no filenames.
--dryrun | If added, no actual commands are executed

##### Restoring:

On the command line, run:
`xe vm-import filename=[path to .xva file]`


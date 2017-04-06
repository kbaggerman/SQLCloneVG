
#variables
$ntnx_cluster = "10.21.9.37"
$ntnx_user_name = "admin"
$ntnx_user_password = "xTreme7452!" | ConvertTo-SecureString -AsPlainText -Force
$ntnx_prot_domain_name= "ProdSQL"
$ntnx_vg_name = "ProdSQL_VG1"
$ntnx_vg_prefix = "test_"
$vm_production = "ProdSQL"
$vm_test = "TestSQL"

# connection / plugin checks
$ntnx_pssnapin_check = Get-PSSnapin | Where {$_.name -eq "NutanixCmdletsPssnapin"}
if(! $ntnx_pssnapin_check)
	{Add-PSSnapin NutanixCmdletsPssnapin}
$cluster = Get-NTNXCluster
if(! $cluster)
	{connect-ntnxcluster -server $ntnx_cluster -username $ntnx_user_name -password $ntnx_user_password -AcceptInvalidSSLCerts}


# Grab pd snapshot uuid for restore operation
$ntnx_prot_domain = get-ntnxprotectiondomain | Where {$_.name -eq $ntnx_prot_domain_name}
$pd_snapshots = get-ntnxprotectiondomain -name $ntnx_prot_domain_name | Get-NTNXProtectionDomainSnapshot
$ntnx_vg_current_check = get-ntnxvolumegroups | where {$_.name -match $ntnx_vg_prefix}
if($ntnx_vg_current_check){echo ""Found Existing" + $ntnx_vg_prefix + " volume group""}
$pd_snapshot_recent_id = $pd_snapshots[0].snapshotid


# Grab volume group uuid
$ntnx_vg_uuid = (Get-NTNXVolumeGroups | where {$_.name -eq $ntnx_vg_name}).uuid
$ntnx_vg_obj = Get-NTNXVolumeGroups | where {$_.name -eq $ntnx_vg_name}
# Restore the protection domain to a new VG
Restore-NTNXEntity -PdName $ntnx_prot_domain_name -VolumeGroupUuids $ntnx_vg_uuid -VgNamePrefix $ntnx_vg_prefix -SnapshotId $pd_snapshot_recent_id




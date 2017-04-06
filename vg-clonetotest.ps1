##########################################################
# vg-clonetotest.ps1
# Created By: Ryan Grendahl
# 4/5/2017
# Description: Designed to be used by Nutanix customers with ESXi using volume group cloning
# to quickly populate a test /dev SQL instance with cloned version of a production database
# 
##########################################################

#Environmentals - Set these for your environment
$ntnx_cluster_ip = "10.21.9.37"
$ntnx_user_name = "admin"
$ntnx_user_password_clear = "xTreme7452!"
$ntnx_user_password = $ntnx_user_password_clear | ConvertTo-SecureString -AsPlainText -Force
$ntnx_pd_name= "ProdSQL"
$ntnx_vg_name = "ProdSQL_VG1"
$ntnx_vg_prefix = "test_"
$vm_test = "TestSQL"

# connection / plugin checks
$ntnx_pssnapin_check = Get-PSSnapin | Where {$_.name -eq "NutanixCmdletsPssnapin"}
if(! $ntnx_pssnapin_check)
	{Add-PSSnapin NutanixCmdletsPssnapin}
$cluster = Get-NTNXCluster
if(! $cluster)
	{connect-ntnxcluster -server $ntnx_cluster_ip -username $ntnx_user_name -password $ntnx_user_password -AcceptInvalidSSLCerts}


# Grab pd snapshot uuid for restore operation
$ntnx_pd = get-ntnxprotectiondomain | Where {$_.name -eq $ntnx_pd_name}
$ntnx_pd_snaps = get-ntnxprotectiondomain -name $ntnx_pd_name | Get-NTNXProtectionDomainSnapshot
$ntnx_vg_current_check = get-ntnxvolumegroups | where {$_.name -match $ntnx_vg_prefix}
if($ntnx_vg_current_check){echo "Existing one found"}
$pd_snap_recent_id = $ntnx_pd_snaps[0].snapshotid


# Grab volume group uuid
$ntnx_vg_uuid = (Get-NTNXVolumeGroups | where {$_.name -eq $ntnx_vg_name}).uuid
$ntnx_vg_obj = Get-NTNXVolumeGroups | where {$_.name -eq $ntnx_vg_name}
# Restore the protection domain to a new VG
Restore-NTNXEntity -PdName $ntnx_pd_name -VolumeGroupUuids $ntnx_vg_uuid -VgNamePrefix $ntnx_vg_prefix -SnapshotId $pd_snap_recent_id

# Attach ISCSI Client to VG
# Grab the ip for the the localhost using Ethernet0 and IPv4 filters
$vmip = (get-netipaddress | where {$_.InterfaceAlias -eq "Ethernet0" -and $_.AddressFamily -eq "IPv4"}).IPAddress
$body = "{""iscsi_client"":
{
       ""client_address"": ""$vmip""
   },
   ""operation"": ""ATTACH""
   }"

$url = "https://${ntnx_cluster_ip}:9440/PrismGateway/services/rest/v2.0/volume_groups/${ntnx_vg_uuid}/close"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ntnx_user_name+":"+$ntnx_user_password_clear ))}
$out = Invoke-RestMethod -Uri $url -Headers $Header -Method Post -Body $body -ContentType application/json


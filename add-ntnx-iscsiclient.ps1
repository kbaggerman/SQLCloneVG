$vmip = "10.21.9.48"

$body = "{""iscsi_client"":
{
       ""client_address"": ""$vmip""
   },
   ""operation"": ""ATTACH""
   }"

$server = "10.21.9.37"
$username = "admin"
$password = "xTreme7452!"
$vguuid = "5a6ea238-a8a6-412c-b84c-bc8d11835106"
$url = "https://${server}:9440/PrismGateway/services/rest/v2.0/volume_groups/${vguuid}/close"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username+":"+$password ))}
$out = Invoke-RestMethod -Uri $url -Headers $Header -Method Post -Body $body -ContentType application/json
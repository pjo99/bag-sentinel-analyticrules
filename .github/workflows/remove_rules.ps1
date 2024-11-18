

$ResourceGroupName = $Env:resourceGroupName
$WorkspaceName = $Env:workspaceName


$rules=Get-AzSentinelAlertRule -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName


$rules | Remove-AzSentinelAlertRule
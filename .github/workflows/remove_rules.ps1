param(
    [string]$resourceGroupName,
    [string]$workspaceName
)

$rules=Get-AzSentinelAlertRule -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName


$rules | Remove-AzSentinelAlertRule
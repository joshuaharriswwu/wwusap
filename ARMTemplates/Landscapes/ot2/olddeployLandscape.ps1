

Write-Host "Provisioning the Jumpbox Server(s)"

Write-Host "Creating Jumpbox Server(s)"
$res = New-AzResourceGroupDeployment -Name "Jumpbox" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\jumpbox\jumpbox.json -TemplateParameterFile .\jumpbox.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}





Write-Host "Deployment finished: " (Get-Date).ToString("yyyy-MM-dd HH:mm")



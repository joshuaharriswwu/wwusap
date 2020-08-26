# select subscription

$ResourceGroupName = "rg-gr2pre"
$location = "ukwest"
$subscriptionID = "c8f03d99-7739-4924-b2a7-5b65bcb69481"
$SID = "gr2"
$applicationSecurityGroupName = "ASG-SAPAPPRDUKW"
$dbSecurityGroupName = "ASG-SAPDBPRDUKW"
$virtualNetworkResourceGroupName = "RG-SAPPREPROD"
$virtualNetworkName = "VNET-SAPPREPRODUKW"


$curDirName = Split-Path $pwd -Leaf  
if ($curDirName.ToLower() -ne ("gr2").ToLower()) {
    Write-Host "Please run the script from the gr2 folder"
    exit 
}

Write-Host "Deployment started: " (Get-Date).ToString("yyyy-MM-dd HH:mm")

$Subscription = Get-AzSubscription -SubscriptionId $SubscriptionId

if (-Not $Subscription) {
    Write-Host -ForegroundColor Red -BackgroundColor White "Sorry, it seems you are not connected to Azure or don't have access to the subscription. Please use Connect-AzAccount to connect."
    exit

}

if (-not (Test-Path ..\..\baseInfrastructure\ppgavset.json -PathType Leaf)) {
    Write-Host -ForegroundColor Red -BackgroundColor White "File ..\..\baseInfrastructure\ppgavset.json does not exit, ensure that your working directory is correct."
    exit
}

Write-Host "Checking prerequisites"
#Checking the VNet
$rgNet = Get-AzResourceGroup -Name $virtualNetworkResourceGroupName -Location $location -ErrorVariable notPresent -ErrorAction SilentlyContinue
if (!$rgNet) {
    $errorInfo = "Resource group '" + $virtualNetworkResourceGroupName + "' does not exist"
    Write-Error -Message $errorInfo -Category ObjectNotFound
    exit
}
else {
    $vnetCheck = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroupName -ErrorAction SilentlyContinue
    if (!$vnetCheck) {
        $errorInfo = "Virtual network '" + $virtualNetworkName + "' does not exist in resource group '" + $virtualNetworkResourceGroupName + "'"
        Write-Error -Message $errorInfo -Category ObjectNotFound
        exit
    }
}

#Check the application security groups
$asg = Get-AzApplicationSecurityGroup -ResourceGroupName $virtualNetworkResourceGroupName -Name $applicationSecurityGroupName -ErrorAction SilentlyContinue
if (!$asg) {
    $errorInfo = "Application security group '" + $applicationSecurityGroupName + "' does not exist in resource group '" + $virtualNetworkResourceGroupName + "'"
    Write-Error -Message $errorInfo -Category ObjectNotFound
    exit
}
else {
    $asg = Get-AzApplicationSecurityGroup -ResourceGroupName $virtualNetworkResourceGroupName -Name $dbSecurityGroupName -ErrorAction SilentlyContinue
    if (!$asg) {
        $errorInfo = "Application security group '" + $dbSecurityGroupName + "' does not exist in resource group '" + $virtualNetworkResourceGroupName + "'"
        Write-Error -Message $errorInfo -Category ObjectNotFound
        exit
    }
}

$rg = Get-AzResourceGroup -Name $ResourceGroupName -Location $location -ErrorVariable notPresent -ErrorAction SilentlyContinue
if (!$rg) {
    Write-Host "Creating the resource group :" $ResourceGroupName
    New-AzResourceGroup -Name $ResourceGroupName -Location $location -Tag @{SID = $SID }
}

# Write-Host "Creating the proximity placement group and the availability sets"
# $res = New-AzResourceGroupDeployment -Name "PPG_AVSet_Creation" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\baseInfrastructure\ppgavset.json -TemplateParameterFile .\ppgavset.parameters.json -Verbose
# if ($res.ProvisioningState -ne "Succeeded") { 
#     Write-Error -Message "The deployment failed" 
#     exit
# }

Write-Host "Provisioning the Database Server(s)"

Write-Host "Creating Db Server(s)"
$res = New-AzResourceGroupDeployment -Name "DbServer_Creation" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\hanaProdVM.json -TemplateParameterFile .\gr2.hanaProdVM.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}


Write-Host "Provisioning the ASCS Server(s)"

Write-Host "Creating ASCS Server(s)"
$res = New-AzResourceGroupDeployment -Name "ASCSServer_Creation" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\ASCSVM.json -TemplateParameterFile .\gr2.ASCSVM.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}


Write-Host "Provisioning the Application Server(s)"

Write-Host "Creating App Server(s)"
$res = New-AzResourceGroupDeployment -Name "AppServer_Creation-app" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\AppVM.json -TemplateParameterFile .\gr2.AppVM.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}


Write-Host "Provisioning the Web Dispatch Server(s)"

Write-Host "Creating Web Dispatch Server(s)"
$res = New-AzResourceGroupDeployment -Name "WebServer_Creation-webdisp" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\WDVM.json -TemplateParameterFile .\gr2.WDVM.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}


Write-Host "Deployment finished: " (Get-Date).ToString("yyyy-MM-dd HH:mm")



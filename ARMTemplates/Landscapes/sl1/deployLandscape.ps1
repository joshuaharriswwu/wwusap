# select subscription

$ResourceGroupName = "rg-sl1prd"
$location = "ukwest"
$subscriptionID = "9617cacf-d020-4b6e-bdf4-5afeea0f3843"
$SID = "sl1"
$applicationSecurityGroupName = "ASG-SAPAPPRDUKW"
$dbSecurityGroupName = "ASG-SAPDBPRDUKW"
$virtualNetworkResourceGroupName = "RG-SAPPROD"
$virtualNetworkName = "VNET-SAPPRODUKW"


$curDirName = Split-Path $pwd -Leaf  
if ($curDirName.ToLower() -ne ("sl1").ToLower()) {
    Write-Host "Please run the script from the sl1 folder"
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
$res = New-AzResourceGroupDeployment -Name "DbServer_Creation" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\hanaProdVM.json -TemplateParameterFile .\sl1.hanaProdVM.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}




Write-Host "Provisioning the Application Server(s)"

Write-Host "Creating App Server(s)"
$res = New-AzResourceGroupDeployment -Name "AppServer_Creation-app" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\servertemplates\AppVM.json -TemplateParameterFile .\sl1.AppVM.parameters.json 
if ($res.ProvisioningState -ne "Succeeded") { 
  Write-Error -Message "The deployment failed" 
}



Write-Host "Deployment finished: " (Get-Date).ToString("yyyy-MM-dd HH:mm")



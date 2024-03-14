$fileName = "$env:FILE_NAME"

$azResourceModule = Get-module -Name Az.Resources
if ($azResourceModule -eq $null) {
    Write-host "Installing Az.Resources module..."
    Install-Module -Name Az.Resources -Repository PSGallery -Force
}

$azAccountModule = Get-module -Name Az.Accounts
if ($azAccountModule -eq $null) {
    Write-host "Installing Az.Accounts module..."
    Install-Module -Name Az.Accounts -Repository PSGallery -Force
}

# Secure credentials creation
Write-Host "Creating secure credential..."
$SecurePassword = ConvertTo-SecureString -String "$env:CLIENT_SECRET" -AsPlainText -Force
$subscriptionId_ENV = "$env:SUBSCRIPTION_ID"
$TenantId = "$env:TENANT_ID"
$ApplicationId = "$env:CLIENT_ID"
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecurePassword

# Connecting to Azure
Write-Host "Connecting to Azure..."
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential | Out-Null
Write-Host "Connected to Azure."

# Assuming multiple files could be found, split the filenames
$FileNames = $fileName -split ', '
foreach ($File in $FileNames) {
    Write-Host "Processing file: $File"
    if (Test-Path $File) {
        $JsonContent = Get-Content $File | ConvertFrom-Json

        $resourceGroupName = $JsonContent.parameters.resourceGroupName.value
        $subscriptionId = $JsonContent.parameters.subscriptionId.value
        $location = $JsonContent.parameters.location.value
        $templateFile = $JsonContent.parameters.templateFilePath.value
        Write-Host "Resource Group Name: $resourceGroupName"
        Write-Host "Subscription ID: $subscriptionId"

        try {
            Write-Host "Setting Azure context to subscription: $subscriptionId"
            Set-AzContext -SubscriptionId $subscriptionId

            Write-Host "Attempting to create new resource group: $resourceGroupName"
            New-AzResourceGroup -Name $resourceGroupName -Location $location

            Write-Host "Deploying template to resource group: $resourceGroupName"
            Write-Host "Using template file: $templateFile"
            New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFile -TemplateParameterFile $File
        }
        catch {
            Write-Host "Error during deployment: $_"
        }
    }
    else {
        Write-Host "File $File not found."
    }
}
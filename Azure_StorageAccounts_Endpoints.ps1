#Install-Module -Name ImportExcel
Import-Module ImportExcel
Import-Module Az.ResourceGraph

$tenants = @{
    # Add azure tenant ids
        #"tenantid1"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid2"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid3"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid4"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid5"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid6"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid7"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid8"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid9"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
        #"tenantid10"="xxxxx-xxxxx-xxxxx-xxxxx-xxxxx" 
}

$ids = $tenants.Values 
ForEach ($id in $ids) {$id

        # Set path and create dynamic file name for export
        $date = get-date
        $fdate = $date.ToString("MM-dd-yyy hh_mm_ss tt")
        $fdate #log to console
        $rpath = %userprofile% # update your path
        $rname = 'Azure_StorageAccounts_Endpoints_' + $id + '_' + $fdate + '.xlsx' # update document name
        $fpath = $rpath + $rname
        $fpath #log to console

# Clearing previous tenant/directory login
#Clear-AzContext -Force
#Login-AzAccount -Credential $Credential -TenantId $id
#Connect-AzAccount -TenantId $id
Set-AzContext -TenantId $id

#Get-AzContext #-ListAvailable
# Fetch the full array of subscription IDs for the tenant
$subscriptions = Get-AzSubscription
$subscriptionIds = $subscriptions.Id

# resource graph query
$query = "where type =~ 'microsoft.storage/storageAccounts' and isnotempty(properties.primaryEndpoints)
|project id, name, tenantId, location, resourceGroup, subscriptionId, properties.primaryEndpoints.table, properties.primaryEndpoints.blob, properties.primaryEndpoints.file, properties.primaryEndpoints.queue, properties.primaryEndpoints.dfs, properties.primaryEndpoints.web, tags, identity";

# Create a subscription counter, set the batch size, and prepare a variable for the results
$counter = [PSCustomObject] @{ Value = 0 }
$batchSize = 1000

$response = @()

# Group the subscriptions into batches
$subscriptionsBatch = $subscriptionIds | Group -Property { [math]::Floor($counter.Value++ / $batchSize) }

# Run the query for each batch
foreach ($batch in $subscriptionsBatch)
{ 
# Create a resource counter, set the batch size, and prepare a variable for the results
$Skip = 0;
$First = 1000;

# Get the data
$response += do {if ($Skip -eq 0) `
    {$y = Search-AzGraph -Query $query -First $First -Subscription $batch.Group ; } `
    else {$y = Search-AzGraph -Query $query -Skip $Skip -First $First -Subscription $batch.Group } `
    $cont = $y.Count -eq $First; $Skip = $Skip + $First; $y; } while ($cont)
}

# View the completed results of the query on all subscriptions
$response | Export-Excel -Path $fpath -Append
}

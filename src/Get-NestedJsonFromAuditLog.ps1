function Get-NestedJsonFromAuditLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $csvPath,

        [Parameter()]
        [string]
        $csvExportPath = "extractedAuditLog.csv"
    )
    $arr = [system.collections.arraylist]::new()
    foreach ($item in $csv) { 
    
        $nestedJson = ($item.AuditData | ConvertFrom-Json)
        $csvObj = [PSCustomObject]@{
            CreationDa     = $item.CreationDate
            Operation      = $nestedJson.Operation
            ObjectId       = $nestedJson.ObjectId
            ItemType       = $nestedJson.ItemType
            SiteURL        = $nestedJson.SiteURL
            SourceFileName = $nestedJson.SourceFileName
    
        }
        $arr.add($csvObj) | Out-Null
    }
   $arr | Export-Csv -Path $csvExportPath
}

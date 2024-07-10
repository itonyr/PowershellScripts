## Auth to PNP online with device auth:

### To run this script you must run the connect-pnponline CMDLET and create an active session with PNPonline.

#### EX: Connect-PnpOnline-url 'demosite.sharepoint.com/sites/sitename' -devicelogin  

function New-FileRestoreWorker {

    [CmdletBinding()]
    param (
        # Email address of the user who deleted the files
        [Parameter(Mandatory = $true)]
        [String]
        $ItemGuidsAsString,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $connection
    )
    $restoredItemsArr = [system.collections.arraylist]::new()
    $failedRestorationArr = [system.collections.arraylist]::new()
    $ItemArr = $ItemGuidsAsString -split (",")
    foreach ($item in $itemArr) {
        try {
            $itemId = $item.Id
            Restore-PnPRecycleBinItem -Identity $itemId.Guid -Force
            $restoredItemsArr.add($item) | out-null
        }
        catch {
            Write-Error $_
            $failedRestorationArr.add($item) | out-null
        }
    }
}

function Get-Batches{ 
   
    $batchStartIndex = 0
    $i = 0
    do{ 
        $batchEndIndex = $batchStartIndex + $dop 
        if ($batchEndIndex -gt $arr.count ){
            $batchEndIndex = ($arr.count -1)
        }
        $ids = $arr[$batchStartIndex..$batchEndIndex]
        $batchObj = @{
            "BatchName" = $i++
            "ids" = $ids
        }
        $arr2.add($batchObj)
       $batchStartIndex = $batchEndIndex
    }until(
        $batchEndIndex -eq $($arr.count -1)
    )
}
 

function Restore-DeletedFilesByUserEmailAddress {
    [CmdletBinding()]
    param (
        # Email address of the user who deleted the files
        [Parameter(Mandatory = $true)]
        [String]
        $UserEmailAddress,

        # Date that the files were deleted. All files deleted by the user defined in the UserEmailAddress field after this date will be restored.
        [Parameter(Mandatory = $true)]
        [String]
        $RestoreFromDate,

        # If this switch is enabled, logs of restoration failures and successes will be exported as csv's to the script root location.
        [Parameter()]
        [switch]
        $LoggingEnabled,

        [Parameter()]
        [switch]
        $dop = 10
    )

   

    begin {

        Write-Host 'Identifying files deleted by {0} after {1}' -f ($UserEmailAddress, $restoreFromDate)
        $deletedItems = Get-PnPRecycleBinItem -RowLimit 500000
        $itemsToRecoverArr = [system.collections.arraylist]::new()
        foreach ($item in $deletedItems) {
            if ($item.DeletedByEmail -like $UserEmailAddress -and $($item.DeletedDate | Get-Date) -gt $restoreFromDate ) {
                $itemsToRecoverArr.add($item) | out-null # Piping to out-null so that we don't write the iterator to console after every add.  
            }
        }

        Write-Host "Total Deleted Items: $($deletedItems.count)"
        Write-Host "Items Deleted by user: $($itemsToRecoverArr.count)"
    }

    process {
        Write-Host "Beginning restore process"
        ## Break items up into batches   
        $batchSize = [math]::floor($itemsToRecoverArr.count / $dop)
        $batchStartIndex = 0
        $i = 0
        $itemBatches = [System.Collections.ArrayList]::new()
        do{ 
            $batchEndIndex = $batchStartIndex + $batchSize 
            if ($batchEndIndex -gt $arr.count ){
                $batchEndIndex = ($arr.count -1)
            }
            $batchItems = $arr[$batchStartIndex..$batchEndIndex]
            $batchObj = @{
                "BatchName" = $i++
                "items" = $batchItems
            }
            $itemBatches.add($batchObj)
           $batchStartIndex = $batchEndIndex
        }until(
            $batchEndIndex -eq $($arr.count -1)
        )
    }

    end {
        if ($loggingEnabled.IsPresent) {
            Write-Host 'Exporting log data..'
            $failedRestorationArr | Export-Csv -path 'FailedRestores.csv'
            $restoredItemsArr | Export-csv -path 'RestoredItems.csv'
        }

        Write-Host "Total Items Restored: $($failedRestorationArr.count)"
        Write-Host "Total Items Failed: $($restoredItemsArr.count)"
    }
}

Restore-DeletedFilesByUserEmailAddress

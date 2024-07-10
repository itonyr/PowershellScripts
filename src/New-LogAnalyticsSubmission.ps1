Function New-LogAnalyticsSubmission {
    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory = $false)]
        $vaultName,

        # The Log Analytics WorkspaceId. This can be found in the 'Overview' tab of the LogAnalyticsWorkspace via the Azure Portal. 
        [Parameter(Mandatory = $false)]
        $LogAnalyticsWorkspaceId, 

        # The Log Analytics Workspace Primary Key. This can be found in the 'Agents Management' tab of the LogAnalyticsWorkspace via the Azure Portal.
        [Parameter(Mandatory = $false)]
        $LogAnalyticsWorkspacePrimaryKey, 

        # Specify the name of the record type that you'll be creating
        [Parameter(Mandatory = $false)]
        $LogType,

        # Optional name of a field that includes the timestamp for the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
        [Parameter(Mandatory = $false)]
        $TimeStampField,
        
        # Make this mandatory later 
        [Parameter(Mandatory = $false)]
        $body,

        [Parameter(Mandatory = $false)]
        $method = 'POST',
            
        [Parameter(Mandatory = $false)]
        $resource = '/api/logs',

        [Parameter(Mandatory = $false)]
        $contentType = "application/json",

        [Parameter(Mandatory = $false)]
        $contentLength = $body.Length,

        [Parameter(Mandatory = $false)]
        $rfc1123date = [DateTime]::UtcNow.ToString("r")
    )


    # This Build-Signature function is coming directly from MS docs so I'm not gonna mess with it. Too much going on.
    Function Build-Signature ($LogAnalyticsWorkspaceId, $LogAnalyticsWorkspacePrimaryKey, $date, $contentLength, $method, $contentType, $resource) {
        $xHeaders = "x-ms-date:" + $date
        $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($LogAnalyticsWorkspacePrimaryKey)

        $sha256 = New-Object System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
        $authorization = 'SharedKey {0}:{1}' -f $LogAnalyticsWorkspaceId, $encodedHash
        return $authorization
    }

    $signatureParams = @{ 
        LogAnalyticsWorkspaceId         = $LogAnalyticsWorkspaceId 
        LogAnalyticsWorkspacePrimaryKey = $LogAnalyticsWorkspacePrimaryKey 
        date                            = $rfc1123date 
        contentLength                   = $contentLength 
        method                          = $method 
        contentType                     = $contentType 
        resource                        = $resource
    } 

    $signature = Build-Signature @signatureParams

    $uri = "https://{0}.ods.opinsights.azure.com{1}?api-version=2016-04-01" -f $LogAnalyticsWorkspaceId, $resource

    $headers = @{
        "Authorization"        = $signature;
        "Log-Type"             = $logType;
        "x-ms-date"            = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }   

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response

}

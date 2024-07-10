function Get-AllSPOSitePermissions { 
    [CmdletBinding()]
    param (
        # EndpointURL to the admin page for a given tenant. Should be in the format of https://{tenantNme}-admin.sharepoint.com
        [Parameter(Mandatory = $true)]
        [string]
        $AdminEndpointURL, 

        # Bool. Display Progress bar in terminal
        [Parameter()]
        [bool]
        $showProgress = $false
    )
    begin { 
        ## This wasn't working if I didn't import the module manually. Idk. 
        ## Piping to Out-Null as this throws an unapproved verb error. 
        $(Import-Module Microsoft.Online.SharePoint.Powershell) | Out-Null
   
        # Interactive Auth 
        Connect-SPOService -Url $adminEndpointUrl

        # Scrape for sites. -Limit All is a required flag to get all sites when there are more than 200 sites associated with a tenant. 
        $sites = Get-SPOSite -Limit All 

        # Init perms array. This is where all userObj's will go after they are parsed and prepared for CSV exporting. 
        $perms = [system.collections.arraylist]::new()
    
        # Init the AccessDeniedExceptions array. This is where the URL for each site that threw a
        # Microsoft.SharePoint.Client.ServerUnauthorizedAccessException will be added. 
        $accessDeniedExceptions = [system.collections.arraylist]::new()
    } 
    process { 
        foreach ($site in $sites) { 
            try { 
                # Declare URL variable as it's used multiple times throughout the below foreach loop
                $url = $site.url
                Write-Host "Scraping permissions for: $url"
                # Scrape for user permissions
                $users = Get-SPOUser -site $url -Limit All
                # Init iterator 
                $i = 0 
                foreach ($user in $users) { 
                    $Completed = ($i / $users.count) * 100
                    $userObj = [PSCustomObject]@{
                        Site        = $url
                        DisplayName = $user.DisplayName
                        LoginName   = $user.LoginName
                        UserType    = $user.UserType
                        isGroup     = $user.isGroup
                    }
                    $perms.add($userObj) | Out-Null
                    if ($showProgress) {
                        $i ++ 
                        Write-Progress -Activity "Scraping user permissions" -Status "Progress:" -PercentComplete $Completed
                    }
                }
            }
            # This catches all access denied exceptions, so these sites can be examined later. 
            catch [Microsoft.SharePoint.Client.ServerUnauthorizedAccessException] { 
                $accessDeniedExceptions.add($url) | Out-Null
            } 
        }
    }
    end{ 
        $perms | Export-csv -path AllSpPermissions.csv -NoTypeInformation
        $accessDeniedExceptions | Export-Csv -path ServerUnauthorizedAccessException.csv -NoTypeInformation
    }
}

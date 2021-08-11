# Usage
# dot source this file, . ./AddReposToGroup.ps1
# executing function
#   Set-Team-Repo-Permissions -AccessToken {personalAccessToken} -OrgName {orgName} -TeamName {teamName} -Permission {optionalPermissionLevel}
# e.g. Set-TeamRepo-Perissions -AccessToken abc123 -OrgName nfl -TeamName giants -Permission admin
# full list of permissions can be found here, https://docs.github.com/en/rest/reference/teams#add-or-update-team-repository-permissions

function Set-Team-Repo-Permissions {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)] [string] $AccessToken,
        [Parameter(Mandatory=$true)] [string] $OrgName,
        [Parameter(Mandatory=$true)] [string] $TeamName,
        [Parameter(Mandatory=$false)] [string] $Permission="maintain"
    )
    $header = @{
        "Authorization" = "token $AccessToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $page = 1
    [array]$allTeams
    [array]$teams = $null
    do {
        Write-Verbose "Retrieving all teams belonging to the $OrgName org"
        $uri = "https://api.github.rackspace.com/orgs/$OrgName/teams?per_page=100&page=$page"
        $teams = Invoke-RestMethod -Method GET -Header $Header -Uri $uri
        $allTeams += $teams
        $page++
    }
    while ($teams.count -gt 0) 
    $teamSlug = $null
    $allTeams | Foreach-Object {
        if ($_.name -eq $TeamName)
        {
            $teamSlug = $_.slug
        }
    }
    Write-Host "Found team slug $teamSlug for team named $TeamName"
    
    $page = 1
    [array]$allRepos
    [array]$repos = $null
    do {
        Write-Verbose "Retrieving all repos belonging to the $OrgName org"
        $uri = "https://api.github.rackspace.com/orgs/$OrgName/repos?per_page=100&page=$page"
        $repos = Invoke-RestMethod -Method GET -Header $Header -Uri $uri
        $allRepos += $repos
        $page++
    }
    while ($repos.count -gt 0) 

    $allRepos | Foreach-Object {
        $repoName = $_.name
        Write-Verbose "Granting $TeamSlug $Permission access to the $OrgName/$repoName"
        $uri = "https://api.github.rackspace.com/orgs/$OrgName/teams/$teamSlug/repos/$OrgName/$repoName"
        $permissionBody = @{
            permission = "$Permission"
        }
        $body = $permissionBody | ConvertTo-Json;
        Invoke-RestMethod -Method PUT -Header $Header -Uri $uri -Body $body
    }

    Write-Host "Granted $TeamName $Permission access to $($allRepos.Count) repos in the $OrgName org"
}
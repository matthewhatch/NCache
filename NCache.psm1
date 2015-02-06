<#
    .Synopsis
    Returns the detailed information about ncache cache

    .Description
    Returns detailed information about an ncache distributed cache based
    on the CacheID that is passed with the CacheID parameter. This is equivalent to 
    running the Alachisift command listcaches /a,  however it targets a specific Cache ID.

    .Parameter ComputerName
    Target machines or an Array of target machines

    .Parameter CacheID
    Name of the Cache on the target machine

    .Example
    Get-CacheDetails -ComputerName Server01 -CacheID Cache00001

    .Example
    Get-CacheDetails -ComputerName Server01,Server02 -CacheID Cache00001
            
#>
function Get-CacheDetails{
    [CmdletBinding()]
    param(
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [string[]]$CacheID,

        [PSCredential]$Credential
    )

    BEGIN{
        $CacheDetailsBlock = {
            $results = & listcaches /a
            Write-Output $results
        }
    
    }
    PROCESS{
        foreach($Computer in $ComputerName){
            
            if($Computer -eq $env:COMPUTERNAME -or $Computer -eq '.'){
                try{$CacheDetails = Get-CacheList }#& listcaches /a}
                catch{ Write-Warning "there was an issue retrieving $CacheID Details from $Computer"}    
            }
            else{
                try{
                    $cimParameters = @{
                        ComputerName = $Computer
                        ScriptBlock = $CacheDetailsBlock
                    }

                    if($PSBoundParameters.ContainsKey('Credential')){
                        $cimParameters.Add('Credential',$Credential)
                    }

                    $CacheDetails = Invoke-Command @cimParameters -ErrorAction Stop
                }
                catch{
                    Write-Warning "there was an issue retrieving $CacheID Details from $Computer"
                }
            }
            if($CacheDetails){
                
                foreach($cache in $CacheID){
                    $StartIndex = __get-cacheStartIndex -CacheList $CacheDetails -CacheID $cache
                    Write-Verbose "The start index is $StartIndex"
        
                    $Clustersize = $CacheDetails[$StartIndex + 3].Replace('Cluster size:','').TrimStart()
                    $properties = @{
                        ComputerName = $Computer
                        CacheId = $CacheDetails[$StartIndex].Replace('Cache-ID:','').TrimStart()
                        Status = $CacheDetails[$StartIndex + 2].Replace('Status:','').TrimStart()
                        ClusterSize = $Clustersize
                        Uptime = $CacheDetails[$StartIndex + (4 + $Clustersize)].Replace('UpTime:','').TrimStart()
                        Capacity = $CacheDetails[$StartIndex + (5 +$Clustersize)].Replace('Capacity:','').TrimStart()
                        Count = $CacheDetails[$StartIndex + (6 + $Clustersize)].Replace('Count:','').TrimStart()
                    }
            
                    $detailsObject = New-Object -TypeName PSObject -Property $properties
            

                    Write-Verbose "validating $cache"
                    if((__ValidateCacheResults $detailsObject $cache)){Write-Output $detailsObject}
                }

                Remove-Variable -Name properties
                Remove-Variable -Name CacheDetails
            }     
        }
    }
    END{}
   
}

<#
    .SYNOPIS 
    Returns the number of items for the cache specified

    .DESCRIPTION
    See Synopis

    .PARAMETER CacheID
    ID of the cache to retreive the count for

    .PARAMETER ComputerName
    The Name of the server to retreive the cache count from
#>
Function Get-CacheCount{
    
    [CmdletBinding()]
    param(
        [string]$CacheID,

        [string[]]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential
    )

    $CacheCountBlock = {
        param ($CacheID)
        $results = & getcachecount $CacheId /nologo
        Write-Output $results
    }

    foreach($Computer in $ComputerName){
        Write-Verbose "Getting the cache count for $CacheID on $Computer"
        
        if($Computer -eq $env:COMPUTERNAME -or $Computer -eq '.'){
            $CacheCount = & getcachecount $CacheId /nologo
        }
        else{
            $cimParameters = @{
                ComputerName = $Computer
                ScriptBlock = $CacheCountBlock
                ArgumentList = $CacheID
            }

            if($PSBoundParameters.ContainsKey('Credential')){
                $cimParameters.Add('Credential',$Credential)
            }

            $CacheCount = Invoke-Command @cimParameters
        }
        
        $properties = @{
            ComputerName = $Computer
            CacheID = $CacheID
            Count = $CacheCount[1].Substring(($CacheCount[1].IndexOf(':') + 1)).replace(' ','')
        }

        $resultObject = New-Object -TypeName PSObject -Property $properties
        Write-Output $resultObject
    }
}

<#
    .Synopsis
        Clears Cache

    .Description
        Clears Ncache on specified target and CacheID

    .Parameter ComputerName
        Name of the target machine

    .Parameter CacheID
        Name of the target Cache

    .Example
        $MyCreds = Get-Credential
        Clear-Cache -ComputerName Server01 -CacheID Cache01 -Credentials $MyCreds

#>
Function Clear-Cache {
    [CmdletBinding()]
    param(
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [string]$CacheID,

        [PSCredential]$Credential
    )

    BEGIN{
        $ClearCacheBlock = {
            param($CacheID)
            
            & clearcache $CacheID /f
        }
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {
            if($Computer -eq $env:COMPUTERNAME){
                $results = & clearcache $CacheID /f    
            }
            else{
                $results = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $ClearCacheBlock -ArgumentList $CacheID
            }
            
            if(-not($results -match 'Cache cleared')){
                 Write-Warning 'There was an issue clearing cache Message:'
                 Write-Warning "$results"
            }
        }    
    }

    END {}

}
function __get-CacheStartIndex{
    param($Cachelist,$CacheID)
    Write-Verbose "Getting the start Index for $CacheID"
       
    #Find the line where cacheid matches the cache if passed
    $i = 0 #start of the array
    while($i -lt ($Cachelist.Length -1)){
        if($Cachelist[$i] -match $CacheID){
            return $i
        }
        $i++
    }
}

function __validateCacheResults{
    param(
        [PSObject]$CacheResults,
        [string]$cache
    )
        
    $isValid = $true
    do{
        if($CacheResults.CacheID -ne $cache){
            Write-Verbose "CacheID $cache is not Valid"
            $isValid = $false
            return
        }

        if($CacheResults.Status -ne 'Running'){
            Write-Verbose "Status $($CacheResults.Status) is not Valid"
            $isValid = $false
            break
        }

        if($CacheResults.Capacity -notmatch 'MB'){
            Write-Verbose "Cluster Capacity$($CacheResults.Capacity) is not valid"
            $isValid =$false 
            break
        }

        if($CacheResults.Clustersize -notmatch '\d+'){
            Write-Verbose "Cluster Size $($CacheResults.ClusterSize) is not valid"   
            $isValid = $false
            break
        }

        if($CacheResults.Count -notmatch '\d+'){
            Write-Verbose "Count $($CacheResults.Count) is not valid"
            $isValid = $false
            break
        }

    }
    while($false)
    return $isValid
}

Function Get-CacheList {
    $results = & listcaches /a
    Write-Output $results   
}

Export-ModuleMember -Function Get-Cache*
Export-ModuleMember -Function Clear-Cache
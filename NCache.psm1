<#
        .Synopsis
        Returns the detailed information about ncache cache

        .Description
        Returns detailed information about an ncache cache that is passed to the
        CacheID parameter

        .Parameter ComputerName
        Name of the server to retreive cache information from

        .Parameter CacheID
        Name of the Cache that to return the details of
            
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

        function __validateCacheResults{
            param([PSObject]$CacheResults)
        
            $isValid = $true
            do{
                if($CacheResults.CacheID -ne $CacheID){
                    Write-Verbose "CacheID $CacheID is not Valid"
                    $isValid = $false
                    break
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
    
    }
    PROCESS{
        foreach($Computer in $ComputerName){
            
            if($Computer -eq $env:COMPUTERNAME -or $Computer -eq '.'){
                try{$CacheDetails = & listcaches /a}
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
            
                    Remove-Variable -Name properties
                    Remove-Variable -Name CacheDetails
            
                    if((__ValidateCacheResults $detailsObject)){Write-Output $detailsObject}
                }

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

function __get-CacheStartIndex{
    param($Cachelist,$CacheID)

    #Find the line where cacheid matches the cache if passed
    $i = 0 #start of the array
    while($i -lt ($Cachelist.Length -1)){
        if($Cachelist[$i] -match $CacheID){
            return $i
            break
        }
        $i++
    }
}

Export-ModuleMember -Function Get-Cache*
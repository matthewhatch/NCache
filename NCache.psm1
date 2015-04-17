#REQUIRES -Version 2.0

<#
    .Synopsis
        Adds a new cache to an NCache Server
    
    .Parameter ComputerName
        Name of Server the cache should be added, this can be an arrat of Computers

    .Parameter ClusterMember
        Name of the other servers in the cluster

    .Parameter CacheID
        Name of the new cache

    .Parameter CacheSize
        Size in MB of the Cache

    .Parameter TopologyName
         Specifies the topology in case of clustered cache. Possible values are
            -local-cache
            -mirror
            -replicated (default)
            -partitioned
            -partitioned-replicas-server

    .Parameter ClusterPort
        Specifies the port of the server, at which server listens. Default is 7800

#>
function New-Cache{
    [CmdletBinding()]
    param(
        [System.String[]]
        $ComputerName,

        [System.String]
        $ClusterMember,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $CacheID,

        [PSCredential]
        $Credential,

        [System.String]
        $EndPoint,
        
        [System.Int16]
        $Port,
        
        [System.Int16]
        $CacheSize,

        [ValidateSet('local-cache','mirror','replicated','partitioned','partitioned-replicas-server')]
        [System.String]
        $TopologyName,

        [Parameter(Mandatory=$true)]
        [System.Int16]
        $ClusterPort

    )

    BEGIN{
        $NewCacheBlock = {
            param($CacheID, $ClusterPort, $TopologyName)
            & createcache $CacheID /c $ClusterPort /t $TopologyName
            & startcache $CacheID
        }

        $AddNodeBlock = {
            param($CacheID,$ComputerName,$ClusterMember)
            & addnode $CacheID /e $ComputerName /n $ClusterMember
        }

    }

    PROCESS{
        
        $parameters = @{
            ComputerName = $ComputerName
            ScriptBlock = $NewCacheBlock
            ArgumentList = @($CacheID,$ClusterPort,$TopologyName)
        }

        if($PSBoundParameters.ContainsKey('Credential')){$parameters.Add('Credential',$Credential)}
        if($PSBoundParameters.ContainsKey('EndPoint')){$parameters.Add('ConfigurationName',$EndPoint)}

        try{
            Write-Verbose "Making remote call to $ComputerName to add $CacheID"
            Invoke-Command  @parameters | Out-Null
            Write-Verbose "$CacheID has been added to $ComputerName"
        }
        catch{
            Write-Warning "There was an issue adding $CacheID in $ComputerName"
        }

        try{
            if($PSBoundParameters.ContainsKey('ClusterMember')){
                Write-Verbose "Making Remote call to $ComputerName to Add $ClusterMember to $CacheID"
                $parameters.ScriptBlock = $AddNodeBlock
                $parameters.ArgumentList = @($CacheID,$ComputerName,$ClusterMember)
                Invoke-Command @parameters | Out-Null
                Write-Verbose "$ClusterMember has been added to $CacheID"   
            }
        }
        catch{
            Write-Warning "There was an issue adding $ClusterMember to $CacheID"
        }
        Get-CacheDetails -ComputerName $ComputerName -Credential $Credential -CacheID $CacheID
    }

    END{
        Remove-Variable -Name AddNodeBlock
        Remove-Variable -Name NewCacheBlock
    }
}


<#
    .Synopsis
        Adds Test data to the specified cache

    .Description
        Adds Test data to the specified cache on a remote server.

    .Parameter ComputerName
        Name of the remote system to add cache items to

    .Parameter CacheID
        Name of the cache to add the test data to

    .Parameter Count
        The number of test items to add to the cache 
    
    .Parameter Credential
        Credential of the user with permission to add data to the cache on the specified server

#>
function Add-CacheTestItem{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [System.string[]]
        $ComputerName = ($env:COMPUTERNAME),

        [Parameter(Mandatory=$true)]
        [System.string]
        $CacheID,

        [System.Int16]
        $Count = 10,

        [System.String]
        $EndPoint,

        [PSCredential]
        $Credential
    )

    BEGIN{
        $AddTestData = {
            param($CacheID,$Count)

            & addtestdata $CacheID /c $Count /nologo
        }
    }
    PROCESS{
        foreach($Computer in $ComputerName){
            if($Computer -eq $env:COMPUTERNAME -or $Computer -eq '.'){
                try{__addtestdata -CacheID $CacheID -Count $Count}
                catch{Write-Warning "There was an issue adding test data to $Computer"}   
            }else{
                $parameters = @{
                    ComputerName = $Computer
                    ScriptBlock = $AddTestData
                    ArgumentList = $CacheID,$Count
                }
                
                if($PSBoundParameters.ContainsKey('Credential')){
                    $parameters.Add('Credential',$Credential)    
                }

                if($PSBoundParameters.ContainsKey('EndPoint')){
                    $parameters.Add('ConfigurationName',$EndPoint)
                }
                
                try{Invoke-Command @parameters | Out-Null}
                catch{Write-Warning "There was an issue adding test data to $Computer"}
            }
        }
    }
    END{}
}
<#
    .Synopsis
    Returns the detailed information about ncache cache

    .Description
    Returns detailed information about an ncache distributed cache based
    on the CacheID that is passed with the CacheID parameter. This is equivalent to
    running the Alachisift command listcaches /a,  however it targets a specific Cache ID.

    The Resulting object will have the following properties: CacheID, ClusterSize, ComputerName, CacheStatus, UpTime

    CacheID: SomeCache
    ClusterSize: 2
    ComputerName: Server01
    CacheStatus: Running


    .Parameter ComputerName
    Target machines or an Array of target machines

    .Parameter CacheID
    Name of the Cache on the target machine

    .Parameter Endpoint
    PS Remoting Endpoint/ConfigurationName that is used when running commands on the remote server
    
    .Parameter Credential
    Credential used to connect to the remote server.  By default the cmdlet will run under your logon credentials

    .Example
    Get-CacheDetails -ComputerName Server01 -CacheID Cache00001

    .Example
    Get-CacheDetails -ComputerName Server01,Server02 -CacheID Cache00001

    .Example
    Get-CacheDeatils -ComputerName Server01 -CacheID Cache0001, Cache0002

    .Example
    Get-CacheDetails -ComputerName Server01 -CacheID Cache0001 -EndPoint ContrainedEndPoint00001

#>
function Get-CacheDetails{
    [CmdletBinding()]
    param(
        [System.string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [System.string[]]
        $CacheID,

        [System.string]
        $Endpoint,

        [PSCredential]
        $Credential
    )

    BEGIN{
        $CacheDetailsBlock = {
            & listcaches /a
        }

    }
    PROCESS{
        foreach($Computer in $ComputerName){

            if($Computer -eq $env:COMPUTERNAME -or $Computer -eq '.'){
                try{$CacheDetails = Get-CacheList }
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

                    if($PSBoundParameters.ContainsKey('Endpoint')){
                        $cimParameters.Add('ConfigurationName',$Endpoint)
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
    .Synopsis
        Restart a cache on a specific server

    .Description
        Performs the stopcache and then startcache actions on a specified cache and server

    .Parameter ComputerName

    .Parameter CacheID

    .Parameter Credential

    .Parameter Endpoint

    .Example
        Restart-Cache -ComputerName Server0001 -CacheID Cache0001 -Credential (Get-Credential)
        

#>
Function Restart-Cache {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [System.string[]]
        $ComputerName,

        [Parameter(Mandatory=$true)]
        [System.String]
        $CacheID,

        [PSCredential]
        $Credential,

        [System.String]
        $Endpoint
    )

    BEGIN{
        #created one block for stop and one for start, running the command in contrained endpoint doesn't allow 
        #for mutiple lines in a script block, Get the errror 'ScriptsNotAllowed'
        
        $StopBlock = {
            param($CacheID)
            & stopcache $CacheID | Out-Null
        }

        $StartBlock = {
            param($CacheID)
            & startcache $CacheID | Out-Null
        }
    }

    PROCESS{
        foreach($computer in $ComputerName){
            $parameters = @{
                ComputerName = $computer
                ArgumentList = $CacheID
            }

            if($PSBoundParameters.ContainsKey('Credential')){
                $parameters.Add('Credential',$Credential)
            }

            if($PSBoundParameters.ContainsKey('Endpoint')){
                $parameters.Add('ConfigurationName',$Endpoint)
            }

            try{
                Invoke-Command @parameters -ScriptBlock $StopBlock
                Invoke-Command @parameters -ScriptBlock $StartBlock
            }
            catch{
                Write-Warning 'There was an issue restarting the cache, here are the parameters you sent'
                Write-Warning $parameters
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

    .Parameter Endpoint
    The name of the Powershell Endpoint/Configuration used when connecting to remote server
#>
function Get-CacheCount{

    [CmdletBinding()]
    param(
        [string]
        $CacheID,

        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [PSCredential]
        $Credential,

        [System.String]
        $Endpoint
    )

    $CacheCountBlock = {
        param ($CacheID)
        & getcachecount $CacheId /nologo
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

            if($PSBoundParameters.ContainsKey('Endpoint')){
                $cimParameters.Add('ConfigurationName',$Endpoint)
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

    .Parameter EndPoint
        Name of PS Remoting Endpoint/Configuration used when connecting to remote servers

    .Example
        $MyCreds = Get-Credential
        Clear-Cache -ComputerName Server01 -CacheID Cache01 -Credentials $MyCreds

#>

Function Clear-Cache {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [System.String]
        $CacheID,

        [PSCredential]
        $Credential,

        [System.String]
        $Endpoint
    )

    BEGIN{
        $ClearCacheBlock = {
            param($CacheID)

            & clearcache $CacheID /f
        }
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {
            if($PSCmdlet.ShouldProcess("$Computer $CacheID")){
                if($Computer -eq $env:COMPUTERNAME){
                    $results = & clearcache $CacheID /f
                }
                else{
                    
                    $cimParameters = @{
                        ComputerName = $Computer
                        ScriptBlock = $ClearCacheBlock
                        ArgumentList = $CacheID
                    }
                    
                    if($PSBoundParameters.ContainsKey('Credential')){
                        $cimParameters.Add('Credential',$Credential)
                    }

                    if($PSBoundParameters.ContainsKey('Endpoint')){
                        $cimParameters.Add('ConfigurationName',$Endpoint)
                    }

                    $results = Invoke-Command @cimParameters
                }

                if(-not($results -match 'Cache cleared')){
                     Write-Warning 'There was an issue clearing cache Message:\
                     '
                     Write-Warning "$results"
                }
            }

        }
    }

    END {}

}

<#
    .Synopsis
        Get Items in Cache

    .Description
        Gets Items in the Target Cache from the Target Server.  This uses the dumpcache cmdline utility and returns the
        data as a PSObject

    .Parameter Computer
        Target Server

    .Parameter CacheID
        Target Cache

    .Parameter Credential
        Credential used to connect to the remote server

    .Parameter Endpoint
        Name of PS Remoting Endpoint/Configuration used when connecting to remote servers

    .Example Get-CacheItem -ComputerName Server0001 -CacheID Cache0001 -Credential (Get-Credential)

#>

Function Get-CacheItem {
    [CmdletBinding()]
    param(
        [System.string]
        $ComputerName,

        [Parameter(Mandatory=$true)]
        [System.string]
        $CacheID,

        [PSCredential]
        $Credential,

        [System.String]
        $Endpoint
    )

    BEGIN{
        $GetCacheItemBlock = {
            param($CacheID)
            & dumpcache $CacheID /nologo
        }
    }

    PROCESS {
        $InvokeParams = @{
            ComputerName = $ComputerName
            ScriptBlock = $GetCacheItemBlock
            ArgumentList = $CacheID
        }
        
        if($PSBoundParameters.ContainsKey('Credential')){
            $InvokeParams.Add('Credential',$Credential)
        }

        if($PSBoundParameters.ContainsKey('Endpoint')){
            $InvokeParams.Add('ConfigurationName',$Endpoint)
        }

        $results = Invoke-Command @InvokeParams

        foreach($result in $results){
            if($result -notmatch 'Alachisoft' -and (-not[string]::IsNullOrEmpty($result)) -and $result -notmatch 'KeyCount' -and $result -notmatch 'Cache Count'){
                $resultArray = $result -split '_'
                $properties = @{
                    CacheKey = $resultArray[0]
                    CacheValue = $resultArray[1]
                    CacheID = $CacheID
                }
                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }
        }
    }

    END {}

}

function __get-CacheStartIndex{
    <#
        .Synopsis Validate the results from cache server are valid

    #>
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

Function __addtestdata {
    param(
        [System.String]
        $CacheID,

        [System.Int16]
        $Count
    )
    & addtestdata $CacheID /c $Count | Out-Null
}

<#
    .Synopsis
        Function is included to help with testing using Pester Mocks
    
    .Describes
        This wraps the external command listcaches in order to make testing easier
        with Pester. In order to Mock calls to listcaches it needs to be wrapped in a 
        function.
#>
Function Get-CacheList{& listcaches /a}

Export-ModuleMember -Function Get-Cache*
Export-ModuleMember -Function Restart-Cache
Export-ModuleMember -Function Clear-Cache
Export-ModuleMember -Function Add-CacheTestItem
Export-ModuleMember -Function New-Cache
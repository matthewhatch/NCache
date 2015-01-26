<#
    Added profix so I know I'm using the version in this repo and not the one in Modules Dir
    Write tests to run disconnected
#>

Import-Module ./NCache.psm1  -Prefix 'Test' -Force 
$secpasswd = ConvertTo-SecureString 'PlainTextPassword' -AsPlainText -Force
$Cred = New-Object -TypeName PSCredential('username',$secpasswd)

Describe 'Get-CacheDetails' {
    Mock -CommandName Invoke-Command -ModuleName NCache {
        $results = @"
Listing registered caches on SOMESERVER:8250

Cache-ID:       mypartitionedcache
Scheme:         partitioned-server
Status:         Stopped

Cache-ID:       somecache
Scheme:         replicated-server
Status:         Running
Cluster size:   2
                1.2.12.60:7802
                1.4.45.36:7802
UpTime:         11/24/2014 6:27:16 AM
Capacity:       250 MB
Count:          0

Cache-ID:       SomeOtherCache_DEV
Scheme:         replicated-server
Status:         Running
Cluster size:   2
                1.2.12.60:7804
                1.4.45.36:7804
UpTime:         11/24/2014 6:27:26 AM
Capacity:       1000 MB
Count:          16

Cache-ID:       SomeOtherCache_dev2
Scheme:         replicated-server
Status:         Running
Cluster size:   2
                1.2.12.60:7803
                1.4.45.36:7803
UpTime:         11/24/2014 6:27:32 AM
Capacity:       1000 MB
Count:          0

Cache-ID:       myreplicatedcache
Scheme:         replicated-server
Status:         Stopped

Cache-ID:       mycache
Scheme:         local-cache
Status:         Stopped
"@  

    Write-Output ($results -split '\r?\n')
    }

    $Cache = Get-TestCacheDetails -ComputerName 'someserver' -CacheID 'somecache' -Credential $cred
    $params = (Get-Command Get-TestCacheDetails).Parameters

    It 'Calls Get-CacheList 1 time'{
        Assert-MockCalled Invoke-Command -ModuleName NCache -Exactly 1
    }

    It 'accepts Credential as a parameter'{
        $params.ContainsKey('Credential') | Should Be $true
    }

    It 'returns an object' {
        $Cache.GetType().Name | Should Be 'PSCustomObject'
    }

    It 'returns object with cache id somecache' {
        $Cache.CacheID | Should Be 'somecache'   
    }

    It 'returns a int as cluster size' {
        ($Cache.ClusterSize -as [System.Int16]).GetType().Name | Should Be 'Int16'
    }

    It 'returns somecache as the cacheID' {
        $Cache.CacheID | Should Be 'somecache'
    }

    It 'returns someserver as Server' {
        $Cache.ComputerName | Should Be 'someserver'
    }
    
    It 'returns an object with property CacheID' {
        (Get-Member -InputObject $Cache).Name -contains 'CacheID' | Should Be $true
    } 

    It 'returns an object with property ComputerName' {
        (Get-Member -InputObject $Cache).Name -contains 'ComputerName' | Should Be $true
    } 

    It 'returns an object with property Count' {
        (Get-Member -InputObject $Cache).Name -contains 'Count' | Should Be $true
    } 

    It 'returns an object with property ClusterSize' {
        (Get-Member -InputObject $Cache).Name -contains 'ClusterSize' | Should Be $true
    } 

    It 'returns an object with property Uptime' {
        (Get-Member -InputObject $Cache).Name -contains 'Uptime' | Should Be $true
    } 

    It 'returns an object with property Status' {
        (Get-Member -InputObject $Cache).Name -contains 'Status' | Should Be $true
    } 

    It 'returns a status of Running or Stopped' {
        $Cache.Status -eq 'Running' -or $Cache.Status -eq 'Stopped' | Should Be $true
    }
}

Describe 'Get-CacheCount' {
    
    Mock Invoke-Command -ModuleName NCache {
        $results = @"

Cache item count: 0
"@

        Write-Output ($results -split '\r?\n')
    }

    $CacheCount = Get-TestCacheCount -CacheID 'somecache' -ComputerName 'someserver' -Credential $cred
    $params = (Get-Command Get-TestCacheCount).Parameters
    
    It 'Should call Invoke-Command 1 time'{
        Assert-MockCalled Invoke-Command -ModuleName NCache -Exactly 1
    }

    It 'Accepts Credential as a parameter'{
        $params.ContainsKey('Credential') | Should Be $true    
    }

    It 'returns an object with property ComputerName' {
        (Get-Member -InputObject $CacheCount).Name -contains 'ComputerName' | Should Be $true    
    }

    It 'returns an object with property CacheId' {
        (Get-Member -InputObject $CacheCount).Name -contains 'CacheId' | Should Be $true    
    }

    It 'returns an object with property Count' {
        (Get-Member -InputObject $CacheCount).Name -contains 'Count' | Should Be $true    
    }

    It 'returns somecache as the cacheID' {
        $CacheCount.CacheID | Should Be 'somecache'
    }

    It 'returns someserver as the ComputerName' {
        $CacheCount.ComputerName | Should Be 'someserver'
    }

    It 'returns a string that can be cast to an int as the Count' {
        ($CacheCount.Count -As [Int16]).GetType().Name | Should Be 'Int16'
    }

    It 'returns a positive value' {
        $CacheCount.Count -ge 0 | Should Be $true
    }
}
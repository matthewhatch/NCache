<#
    Added prefix so I know I'm using the version in this repo and not the one in Modules Dir
    Write tests to run disconnected
#>

Import-Module ./NCache.psm1  -Prefix 'Test' -Force
$secpasswd = ConvertTo-SecureString 'PlainTextPassword' -AsPlainText -Force
$Cred = New-Object -TypeName PSCredential('username',$secpasswd)

Describe 'Get-CacheDetails' {

    $params = (Get-Command Get-TestCacheDetails).Parameters
    $help = Get-Help Get-TestCacheDetails

    Mock -CommandName Get-CacheList -ModuleName NCache {
        $listcaches = @"
Listing registered caches on SOMESERVER:8250

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

"@

            Write-Output ($listcaches -split '\r?\n')
    }

    Mock -CommandName Invoke-Command -ModuleName NCache {
        $listcaches = @"
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

            Write-Output ($listcaches -split '\r?\n')
    }

    Context 'Get-Help Get-CacheDetails'{
        It 'Should have a synopis' {
            $help.synopsis | Should Not Be $null
        }

        It 'Should have a description' {
            $help.description.Text | Should Not Be $null
        }

        It 'Should contain help for ComputerName parameter' {
            $help.parameters.parameter[0].name | Should Be 'ComputerName'
        }

        It 'Should contain help for CacheID parameter' {
            $help.parameters.parameter[1].name | Should Be 'CacheID'
        }
    }
    Context 'Get-CacheDetails from local cache' {
        $localCache = Get-TestCacheDetails -CacheID 'somecache'

        It 'Calls Get-CacheList 1 Time' {
            Assert-MockCalled -CommandName Get-CacheList -ModuleName NCache -Exactly 1
        }

        It 'returns an object' {
            $localCache.GetType().Name | Should Be 'PSCustomObject'
        }

        It 'returns object with cache id somecache' {
            $localCache.CacheID | Should Be 'somecache'
        }

        It 'returns a int as cluster size' {
            ($localCache.ClusterSize -as [System.Int16]).GetType().Name | Should Be 'Int16'
        }

        It 'returns somecache as the cacheID' {
            $localCache.CacheID | Should Be 'somecache'
        }

        It 'returns someserver as Server' {
            $localCache.ComputerName | Should Be $env:Computername
        }

                It 'returns an object with property CacheID' {
            (Get-Member -InputObject $localCache).Name -contains 'CacheID' | Should Be $true
        }

        It 'returns an object with property ComputerName' {
            (Get-Member -InputObject $localCache).Name -contains 'ComputerName' | Should Be $true
        }

        It 'returns an object with property Count' {
            (Get-Member -InputObject $localCache).Name -contains 'Count' | Should Be $true
        }

        It 'returns an object with property ClusterSize' {
            (Get-Member -InputObject $localCache).Name -contains 'ClusterSize' | Should Be $true
        }

        It 'returns an object with property Uptime' {
            (Get-Member -InputObject $localCache).Name -contains 'Uptime' | Should Be $true
        }

        It 'returns an object with property Status' {
            (Get-Member -InputObject $localCache).Name -contains 'Status' | Should Be $true
        }

        It 'returns a status of Running or Stopped' {
            $localCache.Status -eq 'Running' -or $localCache.Status -eq 'Stopped' | Should Be $true
        }
    }
    Context 'Get-CacheDetails from remote cache' {

        $Cache = Get-TestCacheDetails -ComputerName 'someserver' -CacheID 'somecache' -Credential $cred

        It 'Calls Invoke-Commmand 1 time'{
            Assert-MockCalled Invoke-Command -ModuleName NCache -Exactly 1
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

    Context 'Get-CacheDetails from Array of Remote Caches' {
        $CacheArray = Get-TestCacheDetails -ComputerName someserver -CacheID somecache,someothercache_DEV
        It 'returns two objects when an array of two caches is passed to CacheID parameter' {
            $CacheArray.Count | Should Be 2
        }
    }

    Context 'Get-CacheDetails parameters' {
        It 'accepts Credential as a parameter'{
            $params.ContainsKey('Credential') | Should Be $true
        }

        It 'accepts ComputerName as a parameter' {
            $params.ContainsKey('ComputerName') | Should Be $true
        }

        It 'accepts CacheID as a parameter' {
            $params.ContainsKey('CacheID') | Should Be $true
        }
    }


}

Describe 'Get-CacheCount' {

    Mock Invoke-Command -ModuleName NCache {
        $results = @"

Cache item count:10
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

    It 'returns a cache count of 10' {
        $CacheCount.Count | Should Be 10
    }
}

Describe 'Clear-Cache' {
    Context 'Parameters' {
        $params = (Get-Command Clear-TestCache).Parameters

        It 'should accept ComputerName as a parameter' {
            $params.ContainsKey('ComputerName') | Should Be $true
        }

        It 'Should accept CacheID as a parameter' {
            $params.ContainsKey('CacheId') | Should Be $true
        }

        It 'Should accept Credential as a parameter' {
            $params.ContainsKey('Credential') | Should Be $true
        }

    }
}

Describe 'Get-CacheList' {
    Mock -CommandName Invoke-Command -ModuleName NCache {
        $dumpcache = @"
GetProspectClientOrgIds_2503a9cd-b7e4-49a8-a0ec-f921e358432eafm
"@
    Write-Output $dumpcache
    }
    Context 'Parameters' {
        $params = (Get-Command Get-CacheItem).Parameters
        It 'should accept ComputerName as a parameter' {
            $params.ContainsKey('ComputerName') | Should Be $true
        }

        It 'should accept ComputerName as a parameter' {
            $params.ContainsKey('ComputerName') | Should Be $true
        }

        It 'should accept CacheID as a parameter' {
            $params.ContainsKey('CacheID') | Should Be $true
        }

        It 'should accept Credential as a parameter' {
            $params.ContainsKey('Credential') | Should Be $true
        }
    }

    $CacheItems = Get-CacheItem -ComputerName 'server01' -Credential $Cred -CacheID 'Cache001'

    $CacheItems = Get-CacheItem -ComputerName 'server01' -Credential $Cred -CacheID 'Cache001'

    $CacheItems = Get-CacheItem -ComputerName 'server01' -Credential $Cred -CacheID 'Cache001'

    It 'should call Invoke-Command 1 time' {
        Assert-MockCalled -CommandName Invoke-Command -ModuleName NCache -Exactly 1
    }

    It 'Should return an object with with a Key GetProspectClientOrgIds' {
        $CacheItems[0].CacheKey | Should Be 'GetProspectClientOrgIds'
    }

    It 'Should return an object with a Value 2503a9cd-b7e4-49a8-a0ec-f921e358432eafm' {
        $CacheItems[0].CacheValue | Should Be '2503a9cd-b7e4-49a8-a0ec-f921e358432eafm'
    }
}

Describe 'Restart-Cache' {
    Context 'Parameters' {
        $parameters = (Get-Command Restart-Cache).Parameters
        It 'Should accept ComputerName as a parameter' {
            $parameters.ContainsKey('ComputerName') | Should Be $true    
        }
    }
    
}

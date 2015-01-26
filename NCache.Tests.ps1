Import-Module ./NCache.psm1 -Force
$cred = Get-Credential

Describe 'Get-CacheDetails' {
    $Cache = Get-CacheDetails -ComputerName 'johncachd01' -CacheID 'extranetcache' -Credential $cred
    $params = (Get-Command Get-CacheDetails).Parameters

    It 'accepts Credential as a parameter'{
        $params.ContainsKey('Credential') | Should Be $true
    }

    It 'returns an object' {
        $Cache.GetType().Name | Should Be 'PSCustomObject'
    }

    It 'returns object with cache id extranetcache' {
        $Cache.CacheID | Should Be 'ExtranetCache'   
    }

    It 'returns a int as cluster size' {
        ($Cache.ClusterSize -as [System.Int16]).GetType().Name | Should Be 'Int16'
    }

    It 'returns extranetcache as the cacheID' {
        $Cache.CacheID | Should Be 'extranetcache'
    }

    It 'returns johncachd01 as Server' {
        $Cache.ComputerName | Should Be 'johncachd01'
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
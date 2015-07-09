[![Build status](https://ci.appveyor.com/api/projects/status/b1vgvd1vfj91wbhq?svg=true)](https://ci.appveyor.com/project/matthewhatch/ncache)

[![Join the chat at https://gitter.im/matthewhatch/NCache](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/matthewhatch/NCache?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# NCache


NCache Powershell Module -- Used to get data from Alachisoft NCache

I do a lot of work with applications that use Alachisoft's Ncache Distributed Cache and am frustrated with the command line tools that are shipped with the product. Here is a PowerShell module I just started working on to bridge the gap.

Current Cmdlets
* Get-CacheDetails
* Get-CacheCount

TODO
* Add New-Cache Cmdlet
* Add Remove-Cache Cmdlet
* Improved Help
* More Tests

```powershell
Get-CacheDetails -ComputerName Server01 -CacheID Cache0001 -Credential $MyCred
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

Get-CacheCount -ComputerName Server01 -CacheID Cache0001 -Credential $MyCred
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
```



Add-Type -AssemblyName System.Web

function google([Parameter(ValueFromRemainingArguments=$true)][string]$s) {
    function write-bold([string]$s) {
        $i = (-not $s.StartsWith("<b>"))
        $s -split "<b>|</b>" | ? { $_ -ne "" } | % {
            write-host -nonewline -foreground @('white', 'cyan')[($i = -not $i)] $_
        }
        write-host
    }
    $page = 0
    $pages = @(@{start=0})
    while ($page -lt $pages.Count) {
        $c = irm "https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=$([Web.HttpUtility]::UrlEncode($s))&start=$($pages[$page].start)"
        if ($c.responseDetails) { return $c.responseDetails }
        if ($c.responseData.results.Count -eq 0) { return "no results." }
        $pages = $c.responseData.cursor.pages
        write-host -foreground yellow "`r`nShowing $(1 + $pages[$page].start) to $($c.responseData.results.Count + $pages[$page].start) of $($c.responseData.cursor.resultCount)`r`n"
        $c.responseData.results | % {
            write-bold ([Web.HttpUtility]::HtmlDecode($_.title))
            write-host -foreground darkcyan $_.unescapedUrl
            write-bold ([Web.HttpUtility]::HtmlDecode($_.content))
            write-host
        }
        if (($page = 1 + $page) -lt $pages.Count) {
            write-host "any key for more results, q to quit.."
            if ([Console]::ReadKey($true).Key -eq "q") { break }
        }
    }
}
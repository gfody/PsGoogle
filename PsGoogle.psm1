Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Management.Automation

function google([Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments = $true)][string]$q, [int]$n = 4, [switch]$o) {
    function parse-results([string]$html) {
        $reg = new-object Text.RegularExpressions.Regex('class="r"><a href="/url\?q=(.*?)&amp;sa=.*?>(.*?)</a.*?<span class="st">(.*?)</span',
            @([Text.RegularExpressions.RegexOptions]::IgnoreCase, [Text.RegularExpressions.RegexOptions]::Singleline, [Text.RegularExpressions.RegexOptions]::Compiled))
        $reg.Matches($html) | % {
            new-object PSObject -prop @{
                'url' = [Web.HttpUtility]::UrlDecode([Web.HttpUtility]::UrlDecode($_.groups[1].value))
                'title' = [Web.HttpUtility]::HtmlDecode($_.groups[2].value)
                'summary' = [Web.HttpUtility]::HtmlDecode(($_.groups[3].value -replace '(?!</?b>)<.*?>', '')).Replace("`n", "").Trim()
            }
        }
    }
    function write-bold([string]$s) {
        $i = (-not $s.StartsWith("<b>"))
        $s -split "<b>|</b>" | ? { $_ -ne "" } | % {
            write-host -nonewline -foreground @('white', 'cyan')[($i = -not $i)] $_
        }
        write-host
    }

    $num = if ($n -gt 100) { 100 } else { $n }; $start = 0
    while (!$o -or $start -lt $n) {
        $raw = irm "https://www.google.com/search?q=$([Web.HttpUtility]::UrlEncode($q))&start=$start&num=$num"
        $stats = ([regex]'id="resultStats">(.*?)<').match($raw).groups[1].value
        if (!$stats) { if (!$o -and $start -eq 0) { write-host -foreground red "`nno results.`n" }; break }
        $i = $start + 1; $start += $num
        if ($o) { parse-results $raw } else {
            $info = ([regex]'id="topstuff">(?:<(?!h3)[^>]*?>)+(?![<[])(.+?)</div>').match($raw)
            if ($info.success) { write-host -foreground green "`n$([Web.HttpUtility]::HtmlDecode(($info.groups[1].value -replace '<.*?>', ' ' -replace ' {2,}', ' ')).Trim())" }
            write-host -foreground yellow "`n$stats`n"
            parse-results $raw | % {
                write-bold "$(($i++)). $($_.title)"
                write-host -foreground darkcyan $_.url
                if (![string]::isNullOrWhitespace($_.summary)) { write-bold $_.summary }
                write-host
            }
            if (([regex]'position:-96px 0;width:71px').match($raw).success) {
                write-host "any key for more results, q to quit..`n"
                if ([Console]::ReadKey($true).Key -eq "q") { break }
            }
        }
    }
}


if (gcm Register-ArgumentCompleter -ea Ignore) {
    Register-ArgumentCompleter -Command 'google' -Parameter 'q' -Script {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        (irm "https://suggestqueries.google.com/complete/search?output=xml&q=$([Web.HttpUtility]::UrlEncode($wordToComplete))").SelectNodes("/toplevel/CompleteSuggestion/*") | % {
            new-object Management.Automation.CompletionResult($_.data)
        }
    }
}
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Management.Automation

function google([Parameter(Position=0,Mandatory=$true,ValueFromRemainingArguments=$true)][string]$q, [int]$o) {
    function parse-results([string]$html) {
        $reg = new-object Text.RegularExpressions.Regex('class="r"><a href="/url\?q=(.*?)&amp;sa=.*?>(.*?)</a.*?<span class="st">(.*?)</span',
            @([Text.RegularExpressions.RegexOptions]::IgnoreCase, [Text.RegularExpressions.RegexOptions]::Singleline, [Text.RegularExpressions.RegexOptions]::Compiled))
        $reg.Matches($html) | % {
            new-object PSObject -prop @{
                'url' = [Web.HttpUtility]::UrlDecode([Web.HttpUtility]::UrlDecode($_.groups[1].value))
                'title' = [Web.HttpUtility]::HtmlDecode($_.groups[2].value)
                'summary' = [Web.HttpUtility]::HtmlDecode(($_.groups[3].value -replace '(?!</?b>)<.*?>', '')).Replace("`n", "")
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

    $page = 0; $i = 1
    while (!$o -or $o -gt $page) {
        $raw = irm "https://www.google.com/search?q=$([Web.HttpUtility]::UrlEncode($q))&start=$(($page++)*10)"
        $stats = ([regex]'id="resultStats">(.*?)<').match($raw).groups[1].value
        if (!$stats) { if (!$o -and $i -eq 1) { write-host -foreground red "`nno results.`n" }; break }
        if ($o) { parse-results $raw } else {
            $info = ([regex]'id="topstuff">(?:<(?!h3)[^>]*?>)+(?![<[])(.+?)</div>').match($raw)
            if ($info.success) { write-host -foreground green "`n$([Web.HttpUtility]::HtmlDecode(($info.groups[1].value -replace '<.*?>', ' ' -replace ' {2,}', ' ')).Trim())" }
            write-host -foreground yellow "`n$stats`n"
            parse-results $raw | % {
                write-bold "$(($i++)). $($_.title)"
                write-host -foreground darkcyan $_.url
                write-bold $_.summary
                write-host
                if ($i % 5 -eq 0) {
                    write-host "any key for more results, q to quit.."
                    if ([Console]::ReadKey($true).Key -eq "q") { break }
                    write-host
                }
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
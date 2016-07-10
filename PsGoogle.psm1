Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Management.Automation

function google([Parameter(ValueFromRemainingArguments=$true)][string]$s) {
    function write-bold([string]$s) {
        $i = (-not $s.StartsWith("<b>"))
        $s -split "<b>|</b>" | ? { $_ -ne "" } | % {
            write-host -nonewline -foreground @('white', 'cyan')[($i = -not $i)] $_
        }
        write-host
    }

    $page = 0; $c = 1
    while ($true) {
        $doc = (iwr "https://www.google.com/search?q=$([Web.HttpUtility]::UrlEncode($s))&start=$(($page++) * 10)").ParsedHtml
        $stats = $doc.getElementById("resultStats").innerHTML
        if (!$stats -and $c -gt 1) { break } elseif (!$stats) { write-host -foreground red "`nno results.`n"; break }
        write-host -foreground yellow `n$stats`n

        # workaround/speedhack since $doc.getElementsByClassName('g') doesn't work and piping everything back is terribly slow..
        $js = "
            var g = document.getElementsByTagName('div');
            for(var i = 0; i < g.length; i++) {
                if(g[i].className == 'g') {
                    var r = document.createElement('psgoogle');
                    try { r.setAttribute('url', g[i].childNodes[0].childNodes[0].href) } catch(e) {}
                    try { r.setAttribute('text', g[i].childNodes[0].childNodes[0].innerText) } catch(e) {}
                    try { r.setAttribute('title', g[i].childNodes[0].childNodes[0].innerHTML) } catch(e) {}
                    try { r.setAttribute('desc', g[i].childNodes[1].childNodes[1].innerHTML) } catch(e) {}
                    document.appendChild(r);
                }
            }"
        $doc.parentWindow.execScript($js, "javascript")
        $doc.getElementsByTagName("psgoogle") | % {
            $url = $_.getAttribute('url', 1)
            if (!$url) {
                write-host $_.getAttribute('text', 1)
                write-host
            } elseif ($url -ne [DBNull]::Value) {
                write-bold "$(($c++)). $($_.getAttribute('title', 1))"
                write-host -foreground darkcyan ([Web.HttpUtility]::UrlDecode($url.Substring(13, $url.IndexOf("&sa=") - 13)))
                write-bold ([Web.HttpUtility]::HtmlDecode($_.getAttribute('desc', 1)).Replace("<BR>", "`n"))
                write-host
            }

            if ($c % 5 -eq 0) {
                write-host "any key for more results, q to quit.."
                if ([Console]::ReadKey($true).Key -eq "q") { break }
            }
        }
    }
}


if (gcm Register-ArgumentCompleter -ea Ignore) {
    Register-ArgumentCompleter -Command 'google' -Parameter 's' -Script {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        (irm "https://suggestqueries.google.com/complete/search?output=xml&q=$([Web.HttpUtility]::UrlEncode($wordToComplete))").SelectNodes("/toplevel/CompleteSuggestion/*") | % {
            new-object Management.Automation.CompletionResult($_.data)
        }
    }
}
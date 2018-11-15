Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Management.Automation

function Format-Results([string]$html) {
    $reg = New-Object Text.RegularExpressions.Regex('class="r"><a href="/url\?q=(.*?)&amp;sa=.*?>(.*?)</a.*?<span class="st">(.*?)</span',
        @(
          [Text.RegularExpressions.RegexOptions]::IgnoreCase,
          [Text.RegularExpressions.RegexOptions]::Singleline,
          [Text.RegularExpressions.RegexOptions]::Compiled
          )
        )
    $reg.Matches($html) | ForEach-Object {
        New-Object PSObject -Property @{
            'url' = [Web.HttpUtility]::UrlDecode([Web.HttpUtility]::UrlDecode($_.groups[1].value))
            'title' = [Web.HttpUtility]::HtmlDecode($_.groups[2].value)
            'summary' = [Web.HttpUtility]::HtmlDecode(($_.groups[3].value -replace '(<b>|<\/b>)*', '')).Replace("`n", "").Trim()
        }
    }
}

function Format-Bold([string]$s) {
    $i = (-not $s.StartsWith("<b>"))
    $s -split "<b>|</b>" | Where-Object { $_ -ne "" } | ForEach-Object {
        Write-Host -nonewline -foreground @('white', 'cyan')[($i = -not $i)] $_
    }
    Write-Host
}

function Invoke-GoogleSearch {
  <#
  .SYNOPSIS
  This is a small module to invoke a Google Search query and display the results on the command line.
  .DESCRIPTION
  The PsGoogle module allows the user to submit a query string to the Google search engine, and displays the results, all on the command line.
  The module does not use the Google Custom Search API, rather it uses a combination of HTTP requests and regular expressions to extract and display the data.
  .PARAMETER QueryString
  Search string to send to Google.
  .PARAMETER NumberOfResults
  Number of results to return.
  .PARAMETER Objects
  Return the results as an object.
  .EXAMPLE
  PS C:\>Invoke-GoogleSearch What is the meaning of life?

  About 848,000,000 results
  1. Meaning of life - Wikipedia
  https://en.wikipedia.org/wiki/Meaning_of_life
  The meaning of life, or the answer to the question "What is the meaning of life?", <br>pertains to the significance of living or existence in general. Many other related ...

  2. What's the meaning of life? | WIRED UK
  https://www.wired.co.uk/article/what-is-the-meaning-of-life
  11 Aug 2017 ... WIRED asked a philosopher and a physicist to explain the meaning of life.

  3. What is the Meaning of Life? | Psychology Today
  https://www.psychologytoday.com/us/blog/hide-and-seek/201803/what-is-the-meaning-life
  3 Mar 2018 ... The meaning of life is that which we choose to give it.

  4. What Is the Meaning of Life? - The Book of LifeThe Book of Life
  https://www.theschooloflife.com/thebookoflife/the-meaning-of-life/
  Here we want to argue as follows: to wonder about the meaning of life is an <br>extremely important activity, life does have substantial meaning – and there are, ...

  This example shows the most basic use of the command. When run without qualified parameters, the cmdlet assumes that everything following the command name is the query string to send to Google.
  .EXAMPLE
  PS C:\>Invoke-GoogleSearch How much wood could a woodchuck chuck -Objects
  summary                                                                                                                                                         title                                                                   url
  -------                                                                                                                                                         -----                                                                   ---
  How much wood could a woodchuck chuck. If a woodchuck could chuck wood? <br>As much wood as a woodchuck could chuck,. If a woodchuck could chuck wood.          “<b>How much wood could a woodchuck chuck</b> ... ” by Mother Goose ... https://www.poetryfoun...
  How much wood would a woodchuck chuck is an American English-language <br>tongue-twister. The woodchuck from the Algonquian word "wejack" is a kind of ...      <b>How much wood would a woodchuck chuck</b> - Wikipedia                https://en.wikipedia.o...
  New York state wildlife expert Richard Thomas found that a woodchuck could (<br>and does) chuck around 35 cubic feet of dirt in the course of digging a burrow. <b>How much wood would a woodchuck chuck</b> if a woodchuck could ...   https://mylandplan.org...
  How much wood would a woodchuck chuck if a woodchuck could chuck wood? <br>Well, to measure the amount, the chucker had to count, which only a human ...        Urban Dictionary: <b>how much wood would a woodchuck chuck</b> if a ... https://www.urbandicti...

  This example demonstrates the use of the -Objects switch, which returns the search results as objects with the properties 'url', 'title', and 'summary'.
  .EXAMPLE
  PS C:\>Invoke-GoogleSearch How much does a duck weigh? -Objects -NumberOfResults 7 | ForEach-Object ($_.url}
  https://answers.yahoo.com/question/index?qid=20100617221317AAVc6Qn
  http://howtodoright.com/how-much-does-a-duck-weigh/
  https://www.cooksinfo.com/duck
  https://www.researchgate.net/figure/Average-body-weight-kg-of-14-21-and-32-day-old-ducks-by-gait-score-There-was-an_fig1_274092901
  http://www.cs.swan.ac.uk/~csneal/SystemSpec/Different.html
  https://www.quora.com/How-much-does-a-baby-duck-weigh-when-hatched
  https://en.wikipedia.org/wiki/Mallard

  This example demonstrates further use of the -Objects switch in returning only the property 'url' for each of the search results.
  It also demonstrates the use of the -NumberOfResults parameter, increasing the default from 4 results to 7.
  .EXAMPLE
  PS C:\>Get-Content -Path C:\example.txt | Invoke-GoogleSearch
  About 23,900,000 results
  1. PowerShell Scripting | Microsoft Docs
  https://docs.microsoft.com/en-us/powershell/scripting/powershell-scripting
  26 Aug 2018 ... PowerShell commands let you manage computers from the command line. <br>PowerShell providers let you access data stores, such as the ...

  2. PowerShell Documentation | Microsoft Docs
  https://docs.microsoft.com/en-us/powershell/
  PowerShell is an open-source project and available for Windows, Linux and <br>macOS. ... PowerShell in Azure Cloud Shell is now availlable in public preview.

  3. PowerShell - Wikipedia
  https://en.wikipedia.org/wiki/PowerShell
  PowerShell is a task automation and configuration management framework from <br>Microsoft, consisting of a command-line shell and associated scripting ...

  4. Powershell Tutorial - Tutorialspoint
  https://www.tutorialspoint.com/powershell/index.htm
  PowerShell Tutorial for Beginners - Learn PowerShell in simple and easy steps <br>starting from basic to advanced concepts with examples including Overview, ...

  This example demonstrates the pipeline input capability of the cmdlet. Here, the contents of example.txt (simply the string 'powershell') is piped into the -QueryString parameter of the Invoke-GoogleSearch command.
  .INPUTS
  System.String
  You can pipe strings, or anything that can be converted to a string, into the -QueryString parameter of the cmdlet.
  .OUTPUTS
  System.Object
  Invoke-GoogleSearch will parse the results of Invoke-RestMethod and display them using Write-Host.
  The results can also be output as system objects (properties) with the following names: url, title, summary.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments = $true, ValueFromPipeline = $true)]
    [string]
    $QueryString,
    [Parameter(Mandatory=$false)]
    [int]
    $NumberOfResults = 4,
    [Parameter(Mandatory=$false)]
    [switch]
    $Objects
  )
  $num = if ($NumberOfResults -gt 100) { 100 } else { $NumberOfResults }; $start = 0
  while (!$Objects -or $start -lt $NumberOfResults) {
    $raw = Invoke-RestMethod "https://www.google.com/search?q=$([Web.HttpUtility]::UrlEncode($QueryString))&start=$start&num=$num"
    $stats = ([regex]'id="resultStats">(.*?)<').match($raw).groups[1].value
      if (!$stats) { if (!$Objects -and $start -eq 0) { Write-Host -foreground red "`nno results.`n" }; break }
        $i = $start + 1; $start += $num
        if ($Objects) { Format-Results $raw } else {
          $info = ([regex]'id="topstuff">(?:<(?!h3)[^>]*?>)+(?![<[])(.+?)<\/div><div class="\w+\s+\w+">([^<]+)').match($raw)
          if ($info.success) { Write-Host -foreground green "`n$([Web.HttpUtility]::HtmlDecode(($info.groups[1,2].value -replace '<.*?>', ' ' -replace ' {2,}', ' ')).Trim())" }
            Write-Host -foreground yellow "`n$stats`n"
            Format-Results $raw | ForEach-Object {
              Format-Bold "$(($i++)). $($_.title)"
              Write-Host -foreground darkcyan $_.url
              if (![string]::isNullOrWhitespace($_.summary)) { Format-Bold $_.summary }
                Write-Host
            }
            if (([regex]'position:-96px 0;width:71px').match($raw).success) {
              if ($PSISE){
                $message = [System.Windows.Forms.MessageBox]::Show("Load more results?","Continue?",4,32)
                  if ($message -eq "No") {break}
              }
              else{
                Write-Host "Press any key for more results, or q to quit..`n"
                if ([Console]::ReadKey($true).Key -eq "q") {break}
              }
            }
        }
  }
}

if (Get-Command Register-ArgumentCompleter -ErrorAction Ignore) {
    Register-ArgumentCompleter -CommandName 'Invoke-GoogleSearch' -ParameterName 'QueryString' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
        (Invoke-RestMethod "https://suggestqueries.google.com/complete/search?output=xml&q=$(
          [Web.HttpUtility]::UrlEncode($wordToComplete))").SelectNodes("/toplevel/CompleteSuggestion/*") |
          ForEach-Object {New-Object Management.Automation.CompletionResult("'$($_.data)'")}
    }
}

Export-ModuleMember -Function Invoke-GoogleSearch

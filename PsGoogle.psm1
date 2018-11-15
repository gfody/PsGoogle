<#
  .SYNOPSIS
  This is a small module to invoke a Google Search query and display the results on the command line.

  .DESCRIPTION
  The PsGoogle module allows the user to submit a query string to the Google search engine, and displays the results, all on the command line.DESCRIPTION
  The module does not use the Google Custom Search API, rather it uses a combination of HTTP requests and regular expressions to extract and display the data.

  .PARAMETER QueryString
  Search string to send to Google.

  .PARAMETER NumberOfResults
  Number of results to return.

  .PARAMETER Objects
  Return the results as an object.

  .EXAMPLE
  Invoke-GoogleSearch What is the meaning of life?

  .EXAMPLE
  Invoke-GoogleSearch
  .INPUTS
  .OUTPUTS
#>

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
        New-Object PSObject -prop @{
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
  [CmdletBinding()]
  param (
    [Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments = $true)]
    [string]
    $QueryString,
    [Parameter(Mandatory=$false)]
    [int]
    $NumberOfResults = 4,
    [Parameter(Mandatory=$false)]
    [switch]
    $Objects
  )
  # Limit to display maximum of 100 results
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
            Format-Results $raw | % {
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

Export-ModuleMember -Cmdlet Invoke-GoogleSearch

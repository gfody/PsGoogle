A "Google" command for PowerShell, e.g.:

![Screenshot](screenshot.png)

Specify `-Objects` to return objects. `-NumberOfResults` is the number of results to retrieve (default is 4)

![Screenshot](screenshot2.png)

# install #
```Install-Module PsGoogle``` (requires [PsGet](http://psget.net) or PowerShell V5 or Win10)

Manual install:
```ni "$(($env:PSModulePath -split ';')[0])\PsGoogle\PsGoogle.psm1" -f -type file -value (Invoke-RestMethod "https://raw.githubusercontent.com/gfody/PsGoogle/master/PsGoogle.psm1")```

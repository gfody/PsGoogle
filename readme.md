A "google" command for powershell, e.g.:

![Screenshot](screenshot.png)

# install #
```install-module psgoogle``` (requires [PsGet](http://psget.net) or Powershell V5 or Win10)

manual install
```ni "$(($env:PSModulePath -split ';')[0])\PsGoogle\PsGoogle.psm1" -f -type file -value (iwr "https://raw.githubusercontent.com/gfody/PsGoogle/master/PsGoogle.psm1").Content```


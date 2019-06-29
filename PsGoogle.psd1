@{
  RootModule = 'PsGoogle.psm1'
  ModuleVersion = '2.0'
  GUID = 'b489de8f-7ecb-4987-b44d-b72af4f69315'
  Author = 'Gordy'
  Description = 'Google web search CLI for Powershell'
  FunctionsToExport = 'Invoke-GoogleSearch'
  PrivateData = @{
    PSData = @{
      ProjectUri = 'https://github.com/gfody/PsGoogle'
      ReleaseNotes = 'Fixed issues #3, #4, #5, #6 (https://github.com/gfody/PsGoogle/issues); added pipelining.'
    }
  }
}

param(
  [string]$Root = (Get-Location).Path
)

$files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.mbt' |
  Where-Object { $_.FullName -notlike '*\_build\*' })

$production = @($files | Where-Object {
    $_.Name -notlike '*_test.mbt' -and $_.Name -notlike '*_wbtest.mbt'
  })
$tests = @($files | Where-Object {
    $_.Name -like '*_test.mbt' -or $_.Name -like '*_wbtest.mbt'
  })

function Get-LineCount([object[]]$Items) {
  if ($null -eq $Items -or $Items.Count -eq 0) {
    return 0
  }
  return (($Items | ForEach-Object {
      (Get-Content -LiteralPath $_.FullName).Count
    } | Measure-Object -Sum).Sum)
}

$productionLines = Get-LineCount $production
$testLines = Get-LineCount $tests

[PSCustomObject]@{
  production_files = $production.Count
  production_lines = $productionLines
  test_files = $tests.Count
  test_lines = $testLines
  total_files = $files.Count
  total_lines = $productionLines + $testLines
} | Format-List

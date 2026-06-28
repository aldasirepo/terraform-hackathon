# cleanup.ps1 - Execute como: .\cleanup.ps1
# Deleta arquivos que precisam ser removidos (limpeza da Tarefa 1)

$tf  = "C:\Users\master\Documents\Claude\Projects\Hackathon FIAP\terraform-hackathon"
$app = "C:\Users\master\Documents\Claude\Projects\Hackathon FIAP\hackathon-fiap"

Write-Host "=== LIMPEZA ===" -ForegroundColor Cyan

$toDelete = @(
  "$tf\fix.py",
  "$tf\.github\workflows\test.yml",
  "$tf\modules\argocd\placeholder.tf",
  "$tf\modules\databases\placeholder.tf",
  "$tf\modules\eks-cluster\placeholder.tf",
  "$tf\modules\network\placeholder.tf",
  "$tf\modules\resources\placeholder.tf",
  "$app\argocd\application.yaml",
  "$app\donation-service\donation-service.exe"
)

foreach ($f in $toDelete) {
  if (Test-Path $f) {
    Remove-Item -Force $f
    Write-Host "  OK: deletado $f" -ForegroundColor Green
  } else {
    Write-Host "  --: nao encontrado $f" -ForegroundColor Gray
  }
}

# __pycache__
Get-ChildItem -Path $app -Recurse -Filter "__pycache__" -Directory |
  ForEach-Object { Remove-Item -Recurse -Force $_.FullName; Write-Host "  OK: $($_.FullName)" -ForegroundColor Green }

Write-Host "`nLimpeza concluida!" -ForegroundColor Green
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "  cd $tf && terraform fmt -recursive"
Write-Host "  git -C $tf add -A && git -C $tf commit -m 'chore: remove dead code and normalize terraform formatting'"
Write-Host "  git -C $app add -A && git -C $app commit -m 'chore: limpeza, ci/cd e docs'"

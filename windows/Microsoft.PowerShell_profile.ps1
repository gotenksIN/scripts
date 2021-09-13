oh-my-posh --init --shell pwsh --config ~\AppData\Local\Programs\oh-my-posh\themes\powerlevel10k_lean.omp.json | Invoke-Expression
Set-Alias neofetch neofetch.ps1
Import-Module -Name Terminal-Icons
function gita([string]$FilePath) { git add "$FilePath" }
function gitc { git commit -S --signoff }
function gitcp([string]$Hash) { git cherry-pick "$Hash" }
function gitcpc { git cherry-pick --continue }
function gitf([string]$PathToFetch) { git fetch "$PathToFetch" }
function gitp { git push }
function gitfp { git push -f }
function gitr { git reset }
function gitrh { git reset --hard }
clear

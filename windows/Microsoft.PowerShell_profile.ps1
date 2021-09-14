# Init oh-my-posh
oh-my-posh --init --shell pwsh --config ~\AppData\Local\Programs\oh-my-posh\themes\wopian.omp.json | Invoke-Expression

# Alias winfetch script to neofetch
Set-Alias neofetch neofetch.ps1

Import-Module -Name Terminal-Icons

# Set git aliases from commmon/aliases
function gita([string]$FilePath) { git add "$FilePath" }
function gitc { git commit -S --signoff }
function gitcp([string]$Hash) { git cherry-pick "$Hash" }
function gitcpc { git cherry-pick --continue }
function gitf([string]$PathToFetch) { git fetch "$PathToFetch" }
function gitp([string]$WhereToPush, [string]$FromWhereToPush) { git push "$WhereToPush" "$FromWhereToPush" }
function gitp([string]$WhereToPush, [string]$FromWhereToPush) { git push -f "$WhereToPush" "$FromWhereToPush" }
function gitr([string]$Hash) { git reset "$Hash" }
function gitrh([string]$Hash) { git reset --hard "$Hash" }

# Clear terminal once profile is finished loading
clear

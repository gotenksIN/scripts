# Init oh-my-posh
oh-my-posh --init --shell pwsh --config ~\AppData\Local\Programs\oh-my-posh\themes\star.omp.json | Invoke-Expression

# Alias winfetch script to neofetch
Set-Alias neofetch pwshfetch-test-1.ps1

Import-Module -Name Terminal-Icons

# Set git aliases from commmon/aliases
function gita([string]$Arg1) { git add "$Arg1" }
function gitc([string]$Arg1, [string]$Arg2) { git commit -S --signoff "$Arg1" "$Arg2" }
function gitcp([string]$Arg1) { git cherry-pick "$Arg1" }
function gitcpc { git cherry-pick --continue }
function gitf([string]$Arg1) { git fetch "$Arg1" }
function gitp([string]$Arg1, [string]$Arg2) { git push "$Arg1" "$Arg2" }
function gitfp([string]$Arg1, [string]$Arg2) { git push -f "$Arg1" "$Arg2" }
function gitr([string]$Arg1) { git reset "$Arg1" }
function gitrh([string]$Arg1) { git reset --hard "$Arg1" }

# Clear terminal once profile is finished loading
clear

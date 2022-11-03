# Init oh-my-posh
oh-my-posh --init --shell pwsh --config ~\AppData\Local\Programs\oh-my-posh\themes\star.omp.json | Invoke-Expression

# Alias winfetch script to neofetch
Set-Alias neofetch pwshfetch-test-1.ps1

Import-Module -Name Terminal-Icons

# Set git aliases from commmon/aliases
function gita { git add @args }
function gitc { git commit -S --signoff @args }
function gitcp { git cherry-pick @args }
function gitcpc { git cherry-pick --continue }
function gitf { git fetch @args }
function gitp { git push @args }
function gitfp { git push -f @args }
function gitr { git reset @args }
function gitrh { git reset --hard @args }

# Clear terminal once profile is finished loading
clear

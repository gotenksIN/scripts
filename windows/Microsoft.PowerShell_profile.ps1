# Init oh-my-posh
oh-my-posh init pwsh --config "star" | Invoke-Expression

Import-Module Microsoft.WinGet.CommandNotFound
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

# Add some easy download aliases
function quick_download { aria2c -x16 @args }
function pd_download ([string]$id) { aria2c -x16 https://pixeldrain.com/api/file/$id }

# Clear terminal once profile is finished loading
clear

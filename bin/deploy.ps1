param(
    [switch]$Debug
)

$ErrorActionPreference = "Stop"

function Get-NormalizedCookbooks {
    param([string[]]$Cookbooks)
    
    $normalized = @()
    foreach ($raw in $Cookbooks) {
        if (Test-Path $raw -PathType Leaf) {
            $normalized += $raw
        }
        elseif (Test-Path "$raw.rb" -PathType Leaf) {
            $normalized += "$raw.rb"
        }
        elseif (Test-Path "cookbooks\$raw\default.rb" -PathType Leaf) {
            $normalized += "cookbooks\$raw\default.rb"
        }
        elseif (Test-Path "roles\$raw\default.rb" -PathType Leaf) {
            $normalized += "roles\$raw\default.rb"
        }
        else {
            Write-Error "Could not find cookbook for '$raw'"
            exit 1
        }
    }
    return $normalized
}

function Run-Mitamae {
    param(
        [string]$Level,
        [string]$Recipe
    )
    
    $cmd = "mitamae local --shell powershell -l $Level $Recipe"
    
    if ($env:WSL_DISTRO_NAME) {
        # WSL environment
        bash -c "sudo -E $cmd"
    }
    else {
        # Native Windows
        if (-not (Get-Command mitamae -ErrorAction SilentlyContinue)) {
            throw "mitamae not found in PATH. Install with: choco install mitamae"
        }
        Invoke-Expression $cmd
    }
}

# Main execution
. .\bin\setup.ps1

if ($args.Count -eq 0) {
    # Full deployment
    $level = if ($Debug) { "debug" } else { "info" }
    Run-Mitamae -Level $level -Recipe "lib/recipe.rb"
}
else {
    # Individual cookbooks
    $normalized = Get-NormalizedCookbooks -Cookbooks $args
    $level = if ($Debug) { "debug" } else { "info" }
    
    $recipeArgs = @(
        "lib/recipe_helper.rb"
        $normalized
    ) -join " "
    
    Run-Mitamae -Level $level -Recipe $recipeArgs
}

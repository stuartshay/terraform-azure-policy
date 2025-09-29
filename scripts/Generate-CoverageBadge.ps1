#Requires -Modules Pester

<#
.SYNOPSIS
    Generate coverage badge and update README with coverage metrics
.DESCRIPTION
    This script analyzes code coverage data and generates a coverage badge
    for display in the project README. It also updates coverage metrics.
.PARAMETER CoverageReportPath
    Path to the JaCoCo coverage XML file
.PARAMETER BadgeOutputPath
    Path where the coverage badge SVG should be saved
.PARAMETER UpdateReadme
    Switch to automatically update README with coverage percentage
.EXAMPLE
    .\Generate-CoverageBadge.ps1
.EXAMPLE
    .\Generate-CoverageBadge.ps1 -CoverageReportPath "reports/coverage.xml" -UpdateReadme
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$CoverageReportPath = 'reports/coverage.xml',

    [Parameter()]
    [string]$BadgeOutputPath = 'reports/coverage-badge.svg',

    [Parameter()]
    [switch]$UpdateReadme
)

<#
.SYNOPSIS
    Extract coverage percentage from JaCoCo XML report
.PARAMETER ReportPath
    Path to the JaCoCo coverage XML file
.OUTPUTS
    [double] Coverage percentage (0-100)
#>
function Get-CoverageFromJaCoCoReport {
    param([string]$ReportPath)

    if (-not (Test-Path $ReportPath)) {
        Write-Warning "Coverage report not found at: $ReportPath"
        return 0
    }

    try {
        [xml]$coverageXml = Get-Content $ReportPath
        $report = $coverageXml.report

        if ($report.counter) {
            $lineCounter = $report.counter | Where-Object { $_.type -eq 'LINE' }
            if ($lineCounter) {
                $covered = [int]$lineCounter.covered
                $missed = [int]$lineCounter.missed
                $total = $covered + $missed

                if ($total -gt 0) {
                    $percentage = [math]::Round(($covered / $total) * 100, 1)
                    return $percentage
                }
            }
        }

        Write-Warning 'Could not parse coverage data from JaCoCo report'
        return 0
    }
    catch {
        Write-Error "Failed to parse coverage report: $($_.Exception.Message)"
        return 0
    }
}

<#
.SYNOPSIS
    Generate SVG coverage badge based on coverage percentage
.PARAMETER CoveragePercentage
    Coverage percentage (0-100)
.PARAMETER OutputPath
    Path where the badge SVG should be saved
.OUTPUTS
    [bool] True if badge was generated successfully
#>
function New-CoverageBadge {
    param(
        [double]$CoveragePercentage,
        [string]$OutputPath
    )

    # Determine badge color based on coverage percentage
    $color = switch ($CoveragePercentage) {
        { $_ -ge 90 } { 'brightgreen' }
        { $_ -ge 80 } { 'green' }
        { $_ -ge 70 } { 'yellowgreen' }
        { $_ -ge 60 } { 'yellow' }
        { $_ -ge 50 } { 'orange' }
        default { 'red' }
    }

    # Create badge SVG content
    $badgeText = "$CoveragePercentage%"
    $svgContent = @"
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="104" height="20">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="a">
    <rect width="104" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#a)">
    <path fill="#555" d="M0 0h63v20H0z"/>
    <path fill="$color" d="M63 0h41v20H63z"/>
    <path fill="url(#b)" d="M0 0h104v20H0z"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="110">
    <text x="325" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="530">coverage</text>
    <text x="325" y="140" transform="scale(.1)" textLength="530">coverage</text>
    <text x="825" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="310">$badgeText</text>
    <text x="825" y="140" transform="scale(.1)" textLength="310">$badgeText</text>
  </g>
</svg>
"@

    try {
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        # Write SVG content to file
        $svgContent | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "✓ Coverage badge generated: $OutputPath" -ForegroundColor Green
        Write-Host "  Coverage: $badgeText ($color)" -ForegroundColor Gray

        return $true
    }
    catch {
        Write-Error "Failed to generate coverage badge: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Update README.md file with coverage badge and percentage
.PARAMETER CoveragePercentage
    Coverage percentage to display
.OUTPUTS
    [bool] True if README was updated successfully
#>
function Update-ReadmeWithCoverage {
    param(
        [double]$CoveragePercentage
    )

    $readmePath = Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'README.md'

    if (-not (Test-Path $readmePath)) {
        Write-Warning "README.md not found at: $readmePath"
        return $false
    }

    try {
        $readmeContent = Get-Content $readmePath -Raw

        # Update or add coverage badge
        $badgeMarkdown = '![Coverage](./reports/coverage-badge.svg)'

        if ($readmeContent -match '!\[Coverage\]') {
            # Replace existing coverage badge
            $readmeContent = $readmeContent -replace '!\[Coverage\]\([^)]+\)', $badgeMarkdown
            Write-Host '✓ Updated existing coverage badge in README' -ForegroundColor Green
        }
        elseif ($readmeContent -match '(\[!\[CI\][^]]+\][^)]+\))') {
            # Add coverage badge after CI badge
            $readmeContent = $readmeContent -replace '(\[!\[CI\][^]]+\][^)]+\))', "`$1 $badgeMarkdown"
            Write-Host '✓ Added coverage badge to README after CI badge' -ForegroundColor Green
        }
        else {
            # Add at the top of the document after the title
            $lines = $readmeContent -split "`n"
            $titleLineIndex = -1
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match '^# ') {
                    $titleLineIndex = $i
                    break
                }
            }

            if ($titleLineIndex -ge 0) {
                $lines = $lines[0..$titleLineIndex] + '' + $badgeMarkdown + $lines[($titleLineIndex + 1)..($lines.Length - 1)]
                $readmeContent = $lines -join "`n"
                Write-Host '✓ Added coverage badge to README after title' -ForegroundColor Green
            }
        }

        # Write updated content back to README
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8

        Write-Host "  Coverage percentage: $CoveragePercentage%" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Error "Failed to update README: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
try {
    Write-Host 'Coverage Badge Generator' -ForegroundColor Cyan
    Write-Host '========================' -ForegroundColor Cyan
    Write-Host "Coverage Report: $CoverageReportPath" -ForegroundColor Gray
    Write-Host "Badge Output: $BadgeOutputPath" -ForegroundColor Gray

    # Get coverage percentage from report
    $coveragePercentage = Get-CoverageFromJaCoCoReport -ReportPath $CoverageReportPath

    if ($coveragePercentage -eq 0) {
        Write-Warning 'No coverage data found or coverage is 0%. Generating badge with 0% coverage.'
    }

    # Generate coverage badge
    $badgeGenerated = New-CoverageBadge -CoveragePercentage $coveragePercentage -OutputPath $BadgeOutputPath

    if (-not $badgeGenerated) {
        throw 'Failed to generate coverage badge'
    }

    # Update README if requested
    if ($UpdateReadme) {
        Write-Host "`nUpdating README with coverage information..." -ForegroundColor Yellow
        $readmeUpdated = Update-ReadmeWithCoverage -CoveragePercentage $coveragePercentage

        if (-not $readmeUpdated) {
            Write-Warning 'Failed to update README with coverage information'
        }
    }

    Write-Host "`n✓ Coverage badge generation completed successfully!" -ForegroundColor Green
    Write-Host "Badge shows $coveragePercentage% coverage" -ForegroundColor White

    if ($UpdateReadme) {
        Write-Host 'README.md has been updated with the coverage badge' -ForegroundColor White
    }
}
catch {
    Write-Error "Coverage badge generation failed: $($_.Exception.Message)"
    exit 1
}

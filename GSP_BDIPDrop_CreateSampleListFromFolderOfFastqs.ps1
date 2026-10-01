#ChatGPT helped with this one, though I had to extensively troubleshoot encoding issues (don't use UTF encoding)

# Set directory path
$directoryPath = "C:\path\to\FolderWithFastqs"

# Set output CSV file path
$outputCsvPath = Join-Path -Path $directoryPath -ChildPath "SampleList.csv"

# Create an array to store rows
$table = @()

# Row 1: "[Data]"
$table += ,@("[Data]")

# Row 2: Column headers
$table += ,@("Sample_Name", "Project_ID", "File_Forward", "File_Reverse")

# Get all matching .fastq.gz files in path
$fastqFiles = Get-ChildItem -Path $directoryPath -Filter "*.fastq.gz" | Where-Object { -not $_.PSIsContainer }

# Group files by SampleID
$sampleMap = @{}

foreach ($file in $fastqFiles) {
    $fileName = $file.Name

    if ($fileName -match "^(?<SampleID>.+)_1\.fastq\.gz$") {
        $sampleID = $Matches['SampleID']
        if (-not $sampleMap.ContainsKey($sampleID)) {
            $sampleMap[$sampleID] = @{}
        }
        $sampleMap[$sampleID]['Forward'] = $fileName
    }
    elseif ($fileName -match "^(?<SampleID>.+)_2\.fastq\.gz$") {
        $sampleID = $Matches['SampleID']
        if (-not $sampleMap.ContainsKey($sampleID)) {
            $sampleMap[$sampleID] = @{}
        }
        $sampleMap[$sampleID]['Reverse'] = $fileName
    }
}

# Track samples missing pairs
$incompleteSamples = @()

# Add valid rows to table
foreach ($sampleID in $sampleMap.Keys) {
    $forward = $sampleMap[$sampleID]['Forward']
    $reverse = $sampleMap[$sampleID]['Reverse']

    if ($forward -and $reverse) {
        $table += ,@($sampleID, "", $forward, $reverse)
    } else {
        $incompleteSamples += $sampleID
    }
}

# Save CSV (comma-separated, 4 real columns)
$csvContent = $table | ForEach-Object { ($_ -join ",") }
$csvContent | Set-Content -Path $outputCsvPath -Encoding Default
#Don't use UTF encoding here! Adds non-printable characters in output file, causing file upload to fail. 

Write-Output "`n✅ SampleList.csv created at: $outputCsvPath"

# Report any incomplete samples
if ($incompleteSamples.Count -gt 0) {
    Write-Output "`n⚠️ Samples missing forward or reverse file:"
    $incompleteSamples | ForEach-Object { Write-Output " - $_" }
}

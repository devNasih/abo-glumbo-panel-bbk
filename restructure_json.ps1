# PowerShell script to restructure JSON into hierarchical format
# Region -> City -> District

Write-Host "Loading JSON data..." -ForegroundColor Cyan
$jsonContent = Get-Content -Path "geo_units_sorted_by_region_city_district.json" -Raw -Encoding UTF8
$flatData = $jsonContent | ConvertFrom-Json

Write-Host "Processing $($flatData.Count) entries..." -ForegroundColor Cyan

# Group data by region, then city, then district
$regions = @{}

foreach ($entry in $flatData) {
    $regionAr = $entry.region_name_ar
    $regionEn = $entry.region_name_en
    $cityAr = $entry.city_name_ar
    $cityEn = $entry.city_name_en
    $districtAr = $entry.district_name_ar
    $districtEn = $entry.district_name_en
    $districtId = $entry.id
    
    # Initialize region if not exists
    if (-not $regions.ContainsKey($regionAr)) {
        $regions[$regionAr] = @{
            region_ar = $regionAr
            region_en = $regionEn
            cities    = @{}
        }
    }
    
    # Initialize city if not exists
    if (-not $regions[$regionAr].cities.ContainsKey($cityAr)) {
        $regions[$regionAr].cities[$cityAr] = @{
            city_ar   = $cityAr
            city_en   = $cityEn
            districts = @()
        }
    }
    
    # Add district
    $district = @{
        district_id = $districtId.ToString()
        district_ar = $districtAr
        district_en = $districtEn
        latitude    = $entry.latitude
        longitude   = $entry.longitude
    }
    
    $regions[$regionAr].cities[$cityAr].districts += $district
}

Write-Host "Building hierarchical structure..." -ForegroundColor Cyan

# Convert to array format with IDs
$result = @()
$regionId = 1

foreach ($regionKey in ($regions.Keys | Sort-Object)) {
    $region = $regions[$regionKey]
    
    $cities = @()
    $cityId = 1
    
    foreach ($cityKey in ($region.cities.Keys | Sort-Object)) {
        $city = $region.cities[$cityKey]
        
        $cityObj = [PSCustomObject]@{
            city_id   = $cityId.ToString()
            city_ar   = $city.city_ar
            city_en   = $city.city_en
            districts = $city.districts
        }
        
        $cities += $cityObj
        $cityId++
    }
    
    $regionObj = [PSCustomObject]@{
        region_id = $regionId.ToString()
        region_ar = $region.region_ar
        region_en = $region.region_en
        cities    = $cities
    }
    
    $result += $regionObj
    $regionId++
}

Write-Host "Saving hierarchical JSON..." -ForegroundColor Cyan
$outputFile = "geo_units_hierarchical.json"
$result | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "`n✓ Successfully created hierarchical structure!" -ForegroundColor Green
Write-Host "  Regions: $($result.Count)" -ForegroundColor Cyan
Write-Host "  Total cities: $(($result | ForEach-Object { $_.cities.Count } | Measure-Object -Sum).Sum)" -ForegroundColor Cyan
Write-Host "  Total districts: $(($result | ForEach-Object { $_.cities | ForEach-Object { $_.districts.Count } } | Measure-Object -Sum).Sum)" -ForegroundColor Cyan
Write-Host "`nOutput saved to: $outputFile" -ForegroundColor Green

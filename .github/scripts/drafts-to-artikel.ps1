[CmdletBinding()]
param(
    [string]$DraftsPath = '_drafts',
    [string]$PostsPath = '_artikel',
    [string]$ConfigPath = '_config.yml',
    [switch]$AllowMultiplePostsPerDay,
    [switch]$PreserveDateFileName= $true
)

function OutputAction {
    if ($ShouldPublish) {
        $AddFileList = $AddFilesToCommit -join ','
        $RemoveFileList = $RemoveFilesFromCommit -join ','
        'DRAFTS_ARTICLES_RENAMED=true' >> $env:GITHUB_ENV
        'DRAFTS_COMMIT_RENAMED_FILES={0}' -f $AddFileList >> $env:GITHUB_ENV
        'DRAFTS_COMMIT_REMOVED_FILES={0}' -f $RemoveFileList >> $env:GITHUB_ENV
    } else {
        'DRAFTS_ARTICLES_RENAMED=false' >> $env:GITHUB_ENV
        'DRAFTS_COMMIT_RENAMED_FILES=false' >> $env:GITHUB_ENV
        'DRAFTS_COMMIT_REMOVED_FILES=false' >> $env:GITHUB_ENV
    }
}

#region Set Variables
$BasePath = ($PSScriptRoot.Split([System.IO.Path]::DirectorySeparatorChar) | Select-Object -SkipLast 2) -join [System.IO.Path]::DirectorySeparatorChar
$ResolvedDraftsPath = Join-Path -Path $BasePath -ChildPath $DraftsPath -AdditionalChildPath '*'
$ResolvedPostsPath = Join-Path -Path $BasePath -ChildPath $PostsPath
$ResolvedConfigPath = Join-Path -Path $BasePath -ChildPath $ConfigPath
$RenameArticleList = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$AddFilesToCommit = [System.Collections.Generic.List[String]]::new()
$RemoveFilesFromCommit = [System.Collections.Generic.List[String]]::new()
$DateRegex = '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
$ShouldPublish = $false
#endregion

#region Set TimeZone
'::group::Set TimeZone'
$TimeZone = (Get-TimeZone).StandardName
$DefaultTimeZoneMessage = 'Setting TimeZone to default ''{0}''.' -f $TimeZone
try {
    if (Test-Path -Path $ResolvedConfigPath) {
        $TimeZone = (Get-Content -Path $ResolvedConfigPath | ConvertFrom-Yaml).timezone
        if (-Not [string]::IsNullOrEmpty($TimeZone)) {
            'Setting TimeZone from {0} to ''{1}''.' -f $ConfigPath,$TimeZone
        } else {
            $DefaultTimeZoneMessage
        }
    } else {
        $DefaultTimeZoneMessage
    }
}
catch {
    $DefaultTimeZoneMessage
}
$CurrentDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date),$TimeZone)
$CurrentDateOnly = $CurrentDate.Date
$FormattedDate = $CurrentDate.ToString('yyyy-MM-dd')
'::endgroup::'
#endregion

#region Draft Article Discovery
'::group::Draft Article Discovery'
if (-Not (Test-Path -Path $ResolvedDraftsPath)) {
    '::error::The draft path ''{0}'' could not be found' -f $DraftsPath
    exit 1
}
$DraftArticles = Get-ChildItem -Path $ResolvedDraftsPath -Include *.md -Exclude template.md
if ($DraftArticles.Count -gt 0) {
    if ($DraftArticles.Count -eq 1) {
        'Found 1 article in {0}.' -f $DraftsPath
    } else {
        'Found {0} articles in {1}.' -f $DraftArticles.Count,$DraftsPath
    }
    $DraftArticles.Name | ForEach-Object {
        '- {0}' -f $_
    }
} else {
    'No markdown files found in {0}.' -f $DraftsPath
    OutputAction
}
'::endgroup::'
#endregion

#region Checking Draft Article Date
'::group::Checking Draft Article Date'
foreach ($Article in $DraftArticles) {
    $FrontMatter = Get-Content -Path $Article.FullName -Raw | ConvertFrom-Yaml -ErrorAction Ignore
    if ($FrontMatter.ContainsKey('date')) {
        $ArticleDate = [datetime]::Parse($FrontMatter['date'], [System.Globalization.CultureInfo]::InvariantCulture)
        $ArticleDate = [System.TimeZoneInfo]::ConvertTimeFromUtc($ArticleDate, [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone))
        $ArticleDate = $ArticleDate.Date
        '{0}: DATE : {1}' -f $FrontMatter['title'],$ArticleDate
        if ($ArticleDate -le $CurrentDate) {
            $RenameArticleList.Add($Article)
            '{0}: Including article to rename.' -f $FrontMatter['title']
        } else {
            '::warning:: {0}: Article is scheduled for a future date. SKIPPED' -f $FrontMatter['title']
        }
    } else {
        '{0}: Article does not contain a date value. SKIPPED' -f $FrontMatter['title']
    }
}
'::endgroup::'
#endregion

#region Renaming and Moving Draft Articles with Valid Date
if (-Not (Test-Path -Path $ResolvedPostsPath)) {
    '::error::The posts path ''{0}'' could not be found' -f $PostsPath
    OutputAction
    exit 1
}
'::group::Renaming and Moving Draft Articles with Valid Date'
foreach ($Article in $RenameArticleList) {
    $NewFileName = '{0}-{1}' -f $FormattedDate,$Article.Name
    if ($Article.BaseName -match $DateRegex) {
    '::warning::Article filename {0} appears to start with a date format, YYYY-MM-dd.' -f $Article.Name
    if (-not $PreserveDateFileName.IsPresent) {
        '::warning::''PreserveDateFileName'' is enabled. The existing filename will be preserved.'
        $NewFileName = $Article.Name
    } else {
        '::warning::''PreserveDateFileName'' is enabled. The existing filename will be prepended with {0}.' -f $FormattedDate
        $NewFileName = '{0}-{1}' -f $FormattedDate, $Article.Name
    }
}

    'Renaming {0} to {1}' -f $Article.Name,$NewFileName
    $NewFullPath = Join-Path -Path $ResolvedPostsPath -ChildPath $NewFileName
    try {
        Move-Item -Path $Article.FullName -Destination $NewFullPath
        $AddFilesToCommit.Add($NewFileName)
        $RemoveFilesFromCommit.Add($Article.Name)
        $ShouldPublish = $true
    }
    catch {
        OutputAction
    }
}
'::endgroup::'
#endregion

OutputAction

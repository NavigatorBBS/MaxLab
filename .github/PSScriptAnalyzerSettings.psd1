@{
    # PSScriptAnalyzer configuration for MaxLab
    # Specifies which rules to include/exclude

    # Severity level for reporting issues
    Severity = @('Warning', 'Error')

    # Rules to exclude from analysis
    ExcludeRules = @(
        # Write-Host is used for transient UI display messages in setup/start scripts
        # This is an acceptable use case and doesn't violate the intent of the rule
        'PSAvoidUsingWriteHost',

        # Set-CondaChannel and New-CondaEnvironment are internal utility functions,
        # not user-facing cmdlets. They don't need -WhatIf/-Confirm support.
        'PSUseShouldProcessForStateChangingFunctions',

        # These are maintenance/setup scripts, not production code.
        # Aliases like 'cd' are acceptable in internal scripts.
        'PSAvoidUsingCmdletAliases',

        # BOM encoding is a file metadata issue, not a functional problem.
        # PowerShell handles UTF-8 without BOM perfectly fine.
        'PSUseBOMForUnicodeEncodedFile'
    )
}

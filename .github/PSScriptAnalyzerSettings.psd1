@{
    # PSScriptAnalyzer configuration for MaxLab
    # Specifies which rules to include/exclude

    # Severity level for reporting issues
    Severity = @('Warning', 'Error')

    # Rules to exclude from analysis
    ExcludeRules = @(
        # Write-Host is used for transient UI display messages in setup/start scripts
        # This is an acceptable use case and doesn't violate the intent of the rule
        'PSAvoidUsingWriteHost'
    )

    # Other commonly excluded rules can be added here as needed:
    # 'PSUseShouldProcessForStateChangingFunctions' - for simple scripts that don't need -WhatIf
    # 'PSAvoidGlobalVars' - if globals are necessary for your use case
}

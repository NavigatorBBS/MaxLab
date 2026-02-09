"""
NotebookAnalyzerPlugin: Semantic Kernel plugin for analyzing notebook code and structure.

Provides functions for:
- Code syntax and style analysis
- Import analysis
- Data transformation suggestions
- Performance optimization recommendations
"""

import logging
import re
from typing import Annotated

from semantic_kernel.functions import kernel_function

logger = logging.getLogger(__name__)


class NotebookAnalyzerPlugin:
    """
    A Semantic Kernel plugin for analyzing Python notebook cells and structure.
    
    Provides kernel functions decorated for use with Semantic Kernel agents
    to analyze code quality, suggest improvements, and understand notebook content.
    """
    
    @kernel_function(
        description="Check Python code for common issues and suggest improvements",
        name="analyze_code_quality"
    )
    def analyze_code_quality(
        self,
        code_snippet: Annotated[str, "Python code to analyze"]
    ) -> Annotated[str, "Analysis and suggestions"]:
        """
        Analyze Python code snippet for quality issues.
        
        Args:
            code_snippet: The Python code to analyze
            
        Returns:
            A report of issues and suggestions
        """
        issues = []
        
        # Check for missing docstrings
        if "def " in code_snippet and '"""' not in code_snippet and "'''" not in code_snippet:
            issues.append("⚠️  Functions lack docstrings - add documentation")
        
        # Check for hardcoded values
        if re.search(r'=\s*["\'][\w\s]+["\']', code_snippet):
            issues.append("⚠️  Possible hardcoded values - consider parameterizing")
        
        # Check for inefficient pandas operations
        if ".iterrows()" in code_snippet:
            issues.append("⚠️  Expensive .iterrows() detected - use vectorized pandas operations instead")
        
        if ".apply(lambda" in code_snippet:
            issues.append("⚠️  Lambda functions with apply() may be slow - consider vectorized alternatives")
        
        # Check for missing error handling
        if "import" in code_snippet and "try:" not in code_snippet:
            if "requests" in code_snippet or "read_csv" in code_snippet:
                issues.append("ℹ️  Consider adding error handling for file/API operations")
        
        # Check for inefficient concatenation
        if "pd.concat" in code_snippet and re.search(r"for .* in .*:", code_snippet):
            issues.append("⚠️  Concatenating in loops is slow - collect items and concat once")
        
        if not issues:
            return "✅ Code looks good! No major issues detected."
        
        return "\n".join(issues) + "\n\n💡 Tip: Consider profiling critical sections with %timeit or profiling tools."
    
    @kernel_function(
        description="Extract and analyze imports from a notebook cell",
        name="analyze_imports"
    )
    def analyze_imports(
        self,
        code_snippet: Annotated[str, "Python code containing imports"]
    ) -> Annotated[str, "Analysis of imports"]:
        """
        Analyze imports in code snippet.
        
        Args:
            code_snippet: Python code to check for imports
            
        Returns:
            Analysis of imports and recommendations
        """
        import_pattern = r"^(?:from|import)\s+[\w\.]+"
        imports = re.findall(import_pattern, code_snippet, re.MULTILINE)
        
        if not imports:
            return "No imports found in this cell."
        
        analysis = [f"Found {len(imports)} import statement(s):"]
        
        # Check for common patterns
        import_str = "\n".join(imports)
        
        if "import pandas" in import_str and "import numpy" in import_str:
            analysis.append("✓ Core data science libraries (pandas, numpy) found")
        
        if "import matplotlib" in import_str or "import seaborn" in import_str:
            analysis.append("✓ Visualization libraries loaded")
        
        if "import warnings" in import_str:
            analysis.append("✓ Warning management enabled")
        
        # Check for missing common libraries
        if "pd.read_csv" in code_snippet and "import pandas" not in import_str:
            analysis.append("⚠️  Using pandas but pandas not imported - ensure it's in a prior cell")
        
        # Check for wildcard imports
        if "import *" in import_str:
            analysis.append("⚠️  Wildcard imports detected - explicitly list imported names for clarity")
        
        analysis.append("\nImports detected:")
        for imp in imports:
            analysis.append(f"  • {imp}")
        
        return "\n".join(analysis)
    
    @kernel_function(
        description="Summarize what a cell does based on its code",
        name="summarize_cell"
    )
    def summarize_cell(
        self,
        code_snippet: Annotated[str, "Python code from a notebook cell"]
    ) -> Annotated[str, "Summary of what the cell does"]:
        """
        Generate a summary of a notebook cell's purpose.
        
        Args:
            code_snippet: The cell code
            
        Returns:
            A concise summary of the cell's functionality
        """
        actions = []
        
        # Detect common operations
        if "read_csv" in code_snippet or "pd.read" in code_snippet:
            actions.append("Loading data from file")
        
        if "describe()" in code_snippet or "info()" in code_snippet:
            actions.append("Examining data structure and statistics")
        
        if "dropna" in code_snippet or "fillna" in code_snippet:
            actions.append("Handling missing values")
        
        if "groupby" in code_snippet:
            actions.append("Aggregating data by groups")
        
        if "pivot" in code_snippet or "unstack" in code_snippet:
            actions.append("Reshaping data")
        
        if "merge" in code_snippet or "join" in code_snippet:
            actions.append("Combining multiple datasets")
        
        if "plot" in code_snippet or "scatter" in code_snippet or "hist" in code_snippet:
            actions.append("Creating visualizations")
        
        if "apply" in code_snippet or "transform" in code_snippet:
            actions.append("Applying transformations to data")
        
        if "export" in code_snippet or "to_csv" in code_snippet or "to_excel" in code_snippet:
            actions.append("Exporting processed data")
        
        if not actions:
            return "General Python code execution"
        
        return "This cell: " + ", then ".join(actions)
    
    @kernel_function(
        description="Identify data processing steps in pandas code",
        name="identify_data_pipeline"
    )
    def identify_data_pipeline(
        self,
        code_snippet: Annotated[str, "Python pandas code"]
    ) -> Annotated[str, "Identified data processing pipeline"]:
        """
        Identify the data processing pipeline steps.
        
        Args:
            code_snippet: Pandas/data processing code
            
        Returns:
            A description of the data transformation pipeline
        """
        pipeline_steps = []
        
        # Look for chained operations
        operations = [
            ("Load", r"read_csv|read_excel|pd\.(DataFrame|Series)"),
            ("Clean", r"dropna|fillna|drop\(|astype"),
            ("Transform", r"apply|transform|map|str\."),
            ("Aggregate", r"groupby|agg|sum\(|mean\(|count\("),
            ("Reshape", r"pivot|melt|stack|unstack"),
            ("Filter", r"query|\.loc\[|\.iloc\[|where"),
            ("Combine", r"merge|join|concat"),
            ("Visualize", r"plot|scatter|hist|bar"),
            ("Export", r"to_csv|to_excel|to_json"),
        ]
        
        for step_name, pattern in operations:
            if re.search(pattern, code_snippet):
                pipeline_steps.append(step_name)
        
        if not pipeline_steps:
            return "Standard Python data processing (no pandas operations detected)"
        
        pipeline = " → ".join(pipeline_steps)
        return f"Data Pipeline: {pipeline}"
    
    @kernel_function(
        description="Check if code follows pandas best practices",
        name="check_pandas_best_practices"
    )
    def check_pandas_best_practices(
        self,
        code_snippet: Annotated[str, "Python pandas code"]
    ) -> Annotated[str, "Best practice recommendations"]:
        """
        Check pandas code against best practices.
        
        Args:
            code_snippet: Pandas code to check
            
        Returns:
            Recommendations for following pandas best practices
        """
        recommendations = []
        
        # Check for inplace operations
        if ".dropna(inplace=True)" in code_snippet or ".fillna(inplace=True)" in code_snippet:
            recommendations.append("💡 Avoid inplace=True - use assignment instead: `df = df.dropna()`")
        
        # Check for SettingWithCopyWarning prevention
        if ".loc[" in code_snippet and (
            ".copy()" not in code_snippet or ".iloc[" in code_snippet
        ):
            recommendations.append("⚠️  Use .copy() when creating DataFrame subsets to avoid SettingWithCopyWarning")
        
        # Check for index management
        if ".reset_index()" not in code_snippet and "groupby" in code_snippet:
            recommendations.append("💡 Consider reset_index() after groupby() to restore MultiIndex as columns")
        
        # Check for column name specificity
        if re.search(r"df\.iloc\[:,\s*\d", code_snippet):
            recommendations.append("💡 Use column names instead of positional indexing for clarity")
        
        # Check for explicit dtypes on read
        if "read_csv" in code_snippet and "dtype" not in code_snippet:
            recommendations.append("💡 Specify dtype in read_csv() to control data types and improve performance")
        
        if not recommendations:
            recommendations.append("✅ Pandas code follows best practices!")
        
        return "\n".join(recommendations)

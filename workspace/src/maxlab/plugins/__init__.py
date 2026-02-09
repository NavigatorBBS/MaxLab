"""
MaxLab plugins for Semantic Kernel integration.

This module provides reusable plugins for:
- Notebook code analysis and suggestions
- Financial data analysis and categorization
"""

from maxlab.plugins.finance import FinancePlugin
from maxlab.plugins.notebook_analyzer import NotebookAnalyzerPlugin

__all__ = ["FinancePlugin", "NotebookAnalyzerPlugin"]

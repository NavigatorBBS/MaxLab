"""
MaxLab: AI-powered financial analysis with Semantic Kernel integration.

This package provides:
- Semantic Kernel chatbot agents for notebook analysis
- Plugin architecture for extensible AI capabilities
- Financial analysis plugins for transaction categorization and insights
"""

__version__ = "0.1.0"
__author__ = "Chris"

from maxlab.chatbot_agent import NotebookChatAgent, MarkdownResponse
from maxlab.jupyter_extension import load_ipython_extension, unload_ipython_extension

__all__ = ["NotebookChatAgent", "MarkdownResponse", "load_ipython_extension", "unload_ipython_extension"]

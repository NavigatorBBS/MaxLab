"""
Jupyter extension for MaxBot: GitHub Copilot SDK-powered notebook assistant.

This extension automatically:
- Detects GitHub Copilot configuration from environment
- Initializes the NotebookChatAgent
- Exposes the agent in the notebook namespace as 'agent'
- Provides display() and Markdown() utilities for rendering responses

Usage in a notebook cell:
    %load_ext maxbot
    
Then use (response auto-displays as markdown):
    response = await agent.chat("Your question here")
    response
"""

import os
from typing import Optional

from IPython.display import display, Markdown


def load_ipython_extension(ipython):
    """
    Load the MaxBot extension into an IPython kernel.
    
    This is called when a user runs: %load_ext maxbot
    """
    # Import here to avoid circular dependencies
    from maxbot.chatbot_agent import NotebookChatAgent
    
    # Get GitHub Copilot configuration from environment
    github_pat = os.getenv("GITHUB_COPILOT_PAT")
    
    try:
        # Validate that token is provided
        if not github_pat:
            raise ValueError("GITHUB_COPILOT_PAT environment variable not set")
        
        # Initialize the agent
        agent = NotebookChatAgent(github_token=github_pat)
        
        # Inject into IPython namespace
        ipython.user_ns['agent'] = agent
        ipython.user_ns['display'] = display
        ipython.user_ns['Markdown'] = Markdown
        
        # Display status
        display(Markdown(
            "**MaxBot Ready! 🤖**\n\n"
            "🟢 **GitHub Copilot SDK** configured\n\n"
            "Usage:\n"
            "```python\n"
            "# Simple usage - auto-displays as markdown:\n"
            "response = await agent.chat('Your question here')\n"
            "response\n"
            "\n"
            "# Analyze code:\n"
            "response = await agent.chat('Analyze this code for efficiency')\n"
            "\n"
            "# Clear conversation history:\n"
            "await agent.clear_history()\n"
            "\n"
            "# Get conversation messages:\n"
            "messages = await agent.get_messages()\n"
            "\n"
            "# Clean up when done:\n"
            "await agent.cleanup()\n"
            "```"
        ))
        
    except ImportError as e:
        display(Markdown(
            "❌ **MaxBot Extension Failed**\n\n"
            "GitHub Copilot SDK not installed.\n\n"
            "Install with:\n"
            "```bash\n"
            "pip install copilot-sdk\n"
            "```\n\n"
            f"Error: {str(e)}"
        ))
    except ValueError as e:
        display(Markdown(
            "❌ **MaxBot Extension Failed**\n\n"
            "Missing required environment variables:\n\n"
            "```\n"
            f"{str(e)}\n"
            "```\n\n"
            "**For GitHub Copilot SDK**, set:\n"
            "- `GITHUB_COPILOT_PAT` - Your GitHub Copilot Personal Access Token\n\n"
            "Get your token from: https://github.com/settings/tokens"
        ))
    except Exception as e:
        display(Markdown(
            "❌ **MaxBot Extension Error**\n\n"
            "```\n"
            f"{str(e)}\n"
            "```\n\n"
            "Please check your configuration and try again."
        ))


def unload_ipython_extension(ipython):
    """
    Unload the MaxBot extension.
    
    Called when a user runs: %unload_ext maxbot
    """
    for name in ['agent', 'display', 'Markdown']:
        if name in ipython.user_ns:
            del ipython.user_ns[name]

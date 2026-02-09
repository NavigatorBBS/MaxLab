"""
Jupyter extension for MaxLab: Load the agent with %load_ext maxlab

This extension automatically:
- Detects Azure OpenAI or OpenAI configuration from environment
- Initializes the NotebookChatAgent
- Registers default plugins (notebook_analyzer, finance)
- Exposes the agent in the notebook namespace as 'agent'
- Provides display() and Markdown() utilities for rendering responses

Usage in a notebook cell:
    %load_ext maxlab
    
Then use (response auto-displays as markdown):
    response = await agent.chat("Your question here")
    response
"""

import os
from typing import Optional

from IPython.display import display, Markdown


def load_ipython_extension(ipython):
    """
    Load the MaxLab extension into an IPython kernel.
    
    This is called when a user runs: %load_ext maxlab
    """
    # Import here to avoid circular dependencies
    from maxlab.chatbot_agent import NotebookChatAgent
    from maxlab.plugins import FinancePlugin, NotebookAnalyzerPlugin
    
    # Get Azure/OpenAI configuration from environment
    azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    azure_api_key = os.getenv("AZURE_OPENAI_API_KEY")
    azure_deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")
    azure_api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
    openai_api_key = os.getenv("OPENAI_API_KEY")
    
    # Determine which service to use
    use_azure = all([azure_endpoint, azure_api_key, azure_deployment])
    
    if use_azure:
        model_id = azure_deployment
        status_msg = f"🔷 **Azure OpenAI** configured\n- Deployment: `{azure_deployment}`\n- Endpoint: `{azure_endpoint}`\n- API Version: `{azure_api_version}`"
    else:
        model_id = os.getenv("OPENAI_CHAT_MODEL_ID", "gpt-4o")
        status_msg = f"🟢 **OpenAI** configured\n- Model: `{model_id}`"
    
    try:
        # Initialize the agent
        agent = NotebookChatAgent(
            model_id=model_id,
            api_key=openai_api_key,
            use_azure=use_azure,
            azure_endpoint=azure_endpoint,
            azure_api_key=azure_api_key,
            azure_deployment=azure_deployment,
            azure_api_version=azure_api_version,
        )
        
        # Add plugins
        agent.add_plugin(NotebookAnalyzerPlugin(), "notebook_analyzer")
        agent.add_plugin(FinancePlugin(), "finance")
        
        # Inject into IPython namespace
        ipython.user_ns['agent'] = agent
        ipython.user_ns['display'] = display
        ipython.user_ns['Markdown'] = Markdown
        
        # Display status
        display(Markdown(
            f"**MaxLab Ready! 🤖**\n\n"
            f"{status_msg}\n\n"
            f"Available plugins: `notebook_analyzer`, `finance`\n\n"
            f"Usage:\n"
            f"```python\n"
            f"# Simple usage - auto-displays as markdown:\n"
            f"response = await agent.chat('Your question here')\n"
            f"response\n"
            f"\n"
            f"# Or explicitly display:\n"
            f"display(Markdown(response))\n"
            f"```"
        ))
        
    except ValueError as e:
        display(Markdown(
            f"❌ **MaxLab Extension Failed**\n\n"
            f"Missing required environment variables:\n\n"
            f"```\n{str(e)}\n```\n\n"
            f"**For Azure OpenAI**, set:\n"
            f"- `AZURE_OPENAI_ENDPOINT`\n"
            f"- `AZURE_OPENAI_API_KEY`\n"
            f"- `AZURE_OPENAI_DEPLOYMENT_NAME`\n\n"
            f"**For OpenAI**, set:\n"
            f"- `OPENAI_API_KEY`\n"
            f"- Optional: `OPENAI_CHAT_MODEL_ID` (default: `gpt-4o`)"
        ))
    except Exception as e:
        display(Markdown(
            f"❌ **MaxLab Extension Error**\n\n"
            f"```\n{str(e)}\n```"
        ))


def unload_ipython_extension(ipython):
    """
    Unload the MaxLab extension.
    
    Called when a user runs: %unload_ext maxlab
    """
    for name in ['agent', 'display', 'Markdown']:
        if name in ipython.user_ns:
            del ipython.user_ns[name]

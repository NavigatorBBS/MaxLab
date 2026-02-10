"""
NotebookChatAgent: GitHub Copilot SDK agent for interactive notebook analysis.

Provides a chatbot interface that understands notebook content, conda environment,
and can analyze code, suggest improvements, and provide financial insights.
"""

import asyncio
import logging
import re
from typing import Optional, Any, List, Dict

from copilot import CopilotClient

logger = logging.getLogger(__name__)


class MarkdownResponse(str):
    """
    A string subclass that automatically renders as Markdown in Jupyter.
    
    This allows responses to be displayed simply by having them as the last
    expression in a cell, without needing explicit display(Markdown(...)) calls.
    
    Example:
        response = await agent.chat("Your question")
        response  # Automatically displays as formatted markdown
    """
    
    def _repr_markdown_(self):
        """IPython/Jupyter automatically calls this to render markdown."""
        return str(self)


class NotebookChatAgent:
    """
    A GitHub Copilot SDK-based agent for analyzing and interacting with notebook content.
    
    This agent wraps GitHub's Copilot API with notebook-specific context
    and support for code analysis and financial insights.
    
    Attributes:
        client (CopilotClient): The GitHub Copilot SDK client
        session: Current Copilot session
        system_prompt (str): System prompt for the agent
        tools (List): Registered tools for the agent
    """
    
    def __init__(
        self,
        github_token: Optional[str] = None,
        system_prompt: Optional[str] = None,
        model: str = "gpt-4o",
    ):
        """
        Initialize the NotebookChatAgent.
        
        Args:
            github_token: GitHub Copilot token. If None, uses GITHUB_COPILOT_PAT env var
            system_prompt: Custom system prompt for the agent
            model: Model to use (default: gpt-4o)
            
        Raises:
            ImportError: If GitHub Copilot SDK is not installed
            ValueError: If github_token is not provided and GITHUB_COPILOT_PAT env var is not set
        """
        if CopilotClient is None:
            raise ImportError(
                "GitHub Copilot SDK not installed. "
                "Install with: pip install copilot-sdk"
            )
        
        import os
        self.github_token = github_token or os.getenv("GITHUB_COPILOT_PAT")
        
        if not self.github_token:
            raise ValueError(
                "GitHub Copilot PAT not provided. "
                "Set GITHUB_COPILOT_PAT environment variable or pass github_token parameter."
            )
        
        # Initialize client with GitHub token
        self.client = CopilotClient({
            "github_token": self.github_token,
            "log_level": "info",
            "auto_start": True,
        })
        
        self.session = None
        self.model = model
        self.tools = []
        
        # Default system prompt for notebook assistant
        default_system = (
            "You are MaxBot, an AI expert in financial analysis and data science. "
            "You can analyze Python notebook code, understand conda environments, "
            "suggest improvements for financial data processing, and help with transaction categorization. "
            "\n\n"
            "**IMPORTANT**: Always format your responses using Markdown. Use: "
            "headers (#, ##, ###), **bold** and *italic*, `code` blocks, lists, and tables. "
            "Always explain your suggestions clearly and provide code examples when relevant."
        )
        
        self.system_prompt = system_prompt or default_system
        logger.info("NotebookChatAgent initialized with GitHub Copilot SDK")
    
    async def _initialize_session(self) -> None:
        """
        Initialize the Copilot client and create a session.
        
        This is called lazily on first use to ensure async context is available.
        """
        if self.session is not None:
            return
        
        # Start the client
        await self.client.start()
        
        # Create session with system message and tools
        session_config = {
            "model": self.model,
            "system_message": {"role": "system", "content": self.system_prompt},
            "streaming": False,  # Get complete messages
        }
        
        # Add tools if any are registered
        if self.tools:
            session_config["tools"] = self.tools
        
        self.session = await self.client.create_session(session_config)
        logger.info(f"Session created with model {self.model}")
    
    def add_plugin(self, plugin_instance: Any, plugin_name: str) -> None:
        """
        Register a plugin with the agent.
        
        Note: Plugins must be added before the first chat() call.
        After session is created, plugins cannot be added dynamically.
        
        Args:
            plugin_instance: The plugin instance
            plugin_name: Name to register the plugin under
            
        Example:
            agent.add_plugin(NotebookAnalyzerPlugin(), "notebook_analyzer")
        """
        if self.session is not None:
            logger.warning(
                f"Cannot add plugin '{plugin_name}' after session is created. "
                "Plugins must be added before first chat() call."
            )
            return
        
        # Store for context - actual tool registration happens at session creation
        if not hasattr(self, "_plugins"):
            self._plugins = {}
        self._plugins[plugin_name] = plugin_instance
        logger.info(f"Plugin registered: {plugin_name}")

    async def chat(self, user_message: str, as_markdown: bool = True):
        """
        Send a message to the agent and get a response in markdown format.
        
        Uses GitHub Copilot SDK's event-driven session pattern.
        
        Args:
            user_message: The user's message
            as_markdown: If True (default), return response that auto-displays as markdown.
                        If False, strip markdown formatting for plain text response.
            
        Returns:
            MarkdownResponse (auto-displays as markdown in Jupyter) or plain string
            
        Example:
            response = await agent.chat("Analyze this pandas code for efficiency")
            response  # Automatically displays as formatted markdown
            
            # For plain text:
            plain_response = await agent.chat("...", as_markdown=False)
        """
        logger.debug(f"User message: {user_message}")
        
        try:
            # Ensure session is initialized
            await self._initialize_session()
            
            # Use event-driven pattern to get response
            response = await self._send_and_wait(user_message)
            
        except Exception as e:
            logger.error(f"Copilot API error: {e}")
            response = f"❌ **Error communicating with Copilot**\n\n{str(e)}"
        
        # Strip markdown if plain text is requested
        if not as_markdown:
            response = self._strip_markdown(response)
            logger.debug(f"Agent response (plain text): {response}")
            return response
        
        # Return MarkdownResponse for auto-rendering in Jupyter
        logger.debug(f"Agent response: {response}")
        return MarkdownResponse(response)

    async def _send_and_wait(self, user_message: str) -> str:
        """
        Send a message using the session and wait for the response.
        
        Uses the event-driven pattern from GitHub Copilot SDK.
        
        Args:
            user_message: The user's message
            
        Returns:
            Response content from the assistant
        """
        # Track response and completion
        response_content = []
        done = asyncio.Event()
        error_message = None
        
        def on_event(event):
            nonlocal error_message
            
            event_type = event.type.value if hasattr(event.type, 'value') else str(event.type)
            
            if event_type == "assistant.message":
                # Collect the assistant's response
                if hasattr(event.data, 'content'):
                    response_content.append(event.data.content)
                elif isinstance(event.data, dict) and 'content' in event.data:
                    response_content.append(event.data['content'])
                    
            elif event_type == "session.idle":
                # Session finished processing
                done.set()
                
            elif event_type == "error":
                # Handle errors
                error_message = str(event.data) if hasattr(event, 'data') else "Unknown error"
                done.set()
        
        # Register event handler
        self.session.on(on_event)
        
        # Send the message
        await self.session.send({"prompt": user_message})
        
        # Wait for completion (with timeout)
        try:
            await asyncio.wait_for(done.wait(), timeout=60.0)
        except asyncio.TimeoutError:
            return "❌ **Request timed out**\n\nThe agent took too long to respond."
        
        if error_message:
            return f"❌ **Error**\n\n{error_message}"
        
        return response_content[0] if response_content else "No response received."

    def _strip_markdown(self, text: str) -> str:
        """
        Strip markdown formatting from text for plain text response.
        
        Removes:
        - Headers (# ## ###)
        - Bold (**text**)
        - Italic (*text*)
        - Code blocks (```code```)
        - Inline code (`code`)
        - Links [text](url)
        
        Args:
            text: Markdown formatted text
            
        Returns:
            Plain text with markdown removed
        """
        # Remove headers
        text = re.sub(r'^#+\s+', '', text, flags=re.MULTILINE)
        # Remove bold
        text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)
        # Remove italic
        text = re.sub(r'\*(.*?)\*', r'\1', text)
        # Remove code blocks
        text = re.sub(r'```[^`]*```', '', text, flags=re.DOTALL)
        # Remove inline code
        text = re.sub(r'`([^`]*)`', r'\1', text)
        # Remove links (keep text, discard URL)
        text = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', text)
        # Remove extra whitespace
        text = re.sub(r'\n\n+', '\n', text)
        return text.strip()
    
    async def analyze_code(self, code: str, context: Optional[str] = None) -> str:
        """
        Analyze Python code in a notebook cell.
        
        Args:
            code: Python code to analyze
            context: Optional context about the cell (e.g., "data transformation")
            
        Returns:
            Analysis and suggestions for the code
        """
        prompt = f"Please analyze this Python code from a notebook:\n\n```python\n{code}\n```"
        
        if context:
            prompt += f"\n\nContext: {context}"
        
        prompt += (
            "\n\nProvide suggestions for:\n"
            "1. Code efficiency and best practices\n"
            "2. Potential issues or edge cases\n"
            "3. Integration with pandas/numpy workflows\n"
            "4. Performance optimizations"
        )
        
        return await self.chat(prompt)
    
    async def suggest_notebook_improvements(self, notebook_summary: str) -> str:
        """
        Generate suggestions for overall notebook improvements.
        
        Args:
            notebook_summary: Summary of notebook structure and contents
            
        Returns:
            Suggestions for improving the notebook
        """
        prompt = (
            f"Based on this notebook summary, provide specific suggestions for improvement:\n\n"
            f"{notebook_summary}\n\n"
            f"Focus on:\n"
            f"1. Code organization and structure\n"
            f"2. Analysis methodology improvements\n"
            f"3. Visualization enhancements\n"
            f"4. Documentation and clarity"
        )
        
        return await self.chat(prompt)
    
    async def clear_history(self) -> None:
        """
        Clear the conversation history by destroying and recreating the session.
        
        This starts a fresh conversation with the agent.
        """
        if self.session:
            await self.session.destroy()
            self.session = None
        logger.info("Session destroyed - history cleared")
    
    async def get_messages(self) -> List[Dict[str, Any]]:
        """
        Get the current conversation history from the session.
        
        Returns:
            List of message dictionaries with role and content
        """
        if not self.session:
            return []
        
        # GitHub Copilot SDK provides get_messages() on the session
        try:
            messages = await self.session.get_messages()
            return messages if messages else []
        except Exception as e:
            logger.error(f"Failed to get messages: {e}")
            return []
    
    async def cleanup(self) -> None:
        """
        Clean up resources: destroy session and stop client.
        
        Call this when done using the agent to properly release resources.
        """
        if self.session:
            try:
                await self.session.destroy()
                self.session = None
                logger.info("Session destroyed")
            except Exception as e:
                logger.error(f"Failed to destroy session: {e}")
        
        try:
            await self.client.stop()
            logger.info("Client stopped")
        except Exception as e:
            logger.error(f"Failed to stop client: {e}")

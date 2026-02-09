"""
NotebookChatAgent: A Semantic Kernel agent for interactive notebook analysis.

Provides a chatbot interface that understands notebook content, conda environment,
and can analyze code, suggest improvements, and provide financial insights.
"""

import inspect
import logging
import re
from typing import Optional

from semantic_kernel import Kernel
from semantic_kernel.agents import ChatCompletionAgent
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion, OpenAIChatCompletion
from semantic_kernel.exceptions import ServiceResponseException

try:
    from semantic_kernel.contents import ChatHistory
except ImportError:  # Fall back for older SK versions
    from semantic_kernel.chat_completion import ChatHistory

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
    A Semantic Kernel-based agent for analyzing and interacting with notebook content.
    
    This agent wraps OpenAI's ChatCompletionAgent with notebook-specific context
    and plugins for code analysis and financial insights.
    
    Attributes:
        kernel (Kernel): The Semantic Kernel instance
        agent (ChatCompletionAgent): The underlying chat agent
        chat_history (ChatHistory): Conversation history for multi-turn interactions
        model_id (str): The OpenAI model to use (e.g., "gpt-4o")
    """
    
    def __init__(
        self,
        model_id: str = "gpt-4o",
        api_key: Optional[str] = None,
        system_prompt: Optional[str] = None,
        use_azure: bool = False,
        azure_endpoint: Optional[str] = None,
        azure_api_key: Optional[str] = None,
        azure_deployment: Optional[str] = None,
        azure_api_version: Optional[str] = None,
    ):
        """
        Initialize the NotebookChatAgent.
        
        Args:
            model_id: OpenAI model identifier (default: "gpt-4o")
            api_key: OpenAI API key. If None, uses OPENAI_API_KEY env var
            system_prompt: Custom system prompt for the agent
        """
        self.kernel = Kernel()
        self.model_id = model_id
        self.chat_history = ChatHistory()

        # Initialize OpenAI or Azure OpenAI service (handle SDK signature changes)
        if use_azure:
            missing = [
                name
                for name, value in {
                    "AZURE_OPENAI_ENDPOINT": azure_endpoint,
                    "AZURE_OPENAI_API_KEY": azure_api_key,
                    "AZURE_OPENAI_DEPLOYMENT_NAME": azure_deployment,
                }.items()
                if not value
            ]
            if missing:
                raise ValueError(
                    "Azure OpenAI configuration missing: " + ", ".join(missing)
                )

            self.service_id = "azure_openai"
            signature = inspect.signature(AzureChatCompletion)
            params = signature.parameters
            service_kwargs = {}

            if "service_id" in params:
                service_kwargs["service_id"] = self.service_id
            if "endpoint" in params and azure_endpoint is not None:
                service_kwargs["endpoint"] = azure_endpoint
            if "api_key" in params and azure_api_key is not None:
                service_kwargs["api_key"] = azure_api_key
            if "deployment_name" in params and azure_deployment is not None:
                service_kwargs["deployment_name"] = azure_deployment
            elif "deployment_id" in params and azure_deployment is not None:
                service_kwargs["deployment_id"] = azure_deployment
            if "api_version" in params and azure_api_version is not None:
                service_kwargs["api_version"] = azure_api_version
            if "ai_model_id" in params:
                service_kwargs["ai_model_id"] = model_id
            elif "model_id" in params:
                service_kwargs["model_id"] = model_id

            self.kernel.add_service(AzureChatCompletion(**service_kwargs))
        else:
            self.service_id = "openai"
            signature = inspect.signature(OpenAIChatCompletion)
            params = signature.parameters
            service_kwargs = {}

            if "api_key" in params and api_key is not None:
                service_kwargs["api_key"] = api_key
            if "service_id" in params:
                service_kwargs["service_id"] = self.service_id

            if "ai_model_id" in params:
                service_kwargs["ai_model_id"] = model_id
            elif "model_id" in params:
                service_kwargs["model_id"] = model_id

            self.kernel.add_service(OpenAIChatCompletion(**service_kwargs))
        
        # Default system prompt for notebook assistant
        default_system = (
            "You are MaxLab Assistant, an AI expert in financial analysis and data science. "
            "You can analyze Python notebook code, understand conda environments, "
            "suggest improvements for financial data processing, and help with transaction categorization. "
            "You have access to plugins for notebook analysis and financial data insights. "
            "\n\n"
            "**IMPORTANT**: Always format your responses using Markdown. Use: "
            "headers (#, ##, ###), **bold** and *italic*, `code` blocks, lists, and tables. "
            "Always explain your suggestions clearly and provide code examples when relevant."
        )
        
        self.system_prompt = system_prompt or default_system
        agent_signature = inspect.signature(ChatCompletionAgent)
        agent_params = agent_signature.parameters
        agent_kwargs = {
            "kernel": self.kernel,
        }
        if "service_id" in agent_params:
            agent_kwargs["service_id"] = self.service_id
        if "service" in agent_params:
            agent_kwargs["service"] = self.kernel.get_service(self.service_id)
        if "system_prompt" in agent_params:
            agent_kwargs["system_prompt"] = self.system_prompt
        if "system_message" in agent_params:
            agent_kwargs["system_message"] = self.system_prompt

        self.agent = ChatCompletionAgent(**agent_kwargs)
        
        logger.info(f"NotebookChatAgent initialized with model: {model_id}")
    
    def add_plugin(self, plugin_class, plugin_name: str) -> None:
        """
        Register a plugin with the kernel.
        
        Args:
            plugin_class: The plugin class instance with @kernel_function decorated methods
            plugin_name: Name to register the plugin under
            
        Example:
            agent.add_plugin(NotebookAnalyzerPlugin(), "notebook_analyzer")
        """
        self.kernel.add_plugin(plugin_class, plugin_name)
        logger.info(f"Plugin registered: {plugin_name}")
    
    async def chat(self, user_message: str, as_markdown: bool = True):
        """
        Send a message to the agent and get a response in markdown format.
        
        Maintains conversation history for multi-turn interactions.
        
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
        self.chat_history.add_user_message(user_message)
        logger.debug(f"User message: {user_message}")
        
        result = await self._invoke_agent(self.chat_history)
        response = str(result)
        
        # Strip markdown if plain text is requested
        if not as_markdown:
            response = self._strip_markdown(response)
            self.chat_history.add_assistant_message(response)
            logger.debug(f"Agent response: {response}")
            return response
        
        # Return MarkdownResponse for auto-rendering in Jupyter
        self.chat_history.add_assistant_message(response)
        logger.debug(f"Agent response: {response}")
        return MarkdownResponse(response)

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

    async def _invoke_agent(self, chat_history: ChatHistory) -> str:
        """
        Invoke the agent across SDK versions.

        Some Semantic Kernel versions return an async generator from invoke().
        This helper collects the streamed response into a single string.
        """
        try:
            result = self.agent.invoke(chat_history)
            if inspect.isasyncgen(result):
                parts = []
                async for chunk in result:
                    parts.append(str(chunk))
                return "".join(parts)

            return await result
        except ServiceResponseException as e:
            error_msg = str(e)
            if "insufficient_quota" in error_msg or "429" in error_msg:
                return (
                    "❌ **API Quota Exceeded**\n\n"
                    "Your OpenAI API account has no remaining balance or quota.\n\n"
                    "**To fix:**\n"
                    "1. Visit https://platform.openai.com/account/billing/overview\n"
                    "2. Add a payment method or credit\n"
                    "3. Update `OPENAI_API_KEY` in `.env` if using a different account\n"
                )
            elif "authentication" in error_msg.lower() or "invalid" in error_msg.lower():
                return (
                    "❌ **Invalid API Key or Authentication Failed**\n\n"
                    "The OpenAI API key in `.env` is invalid or expired.\n\n"
                    "**To fix:**\n"
                    "1. Get a valid API key from https://platform.openai.com/api-keys\n"
                    "2. Update `OPENAI_API_KEY` in `.env`\n"
                    "3. Restart the kernel and try again\n"
                )
            elif "rate_limit" in error_msg.lower():
                return (
                    "⏱️  **Rate Limit Exceeded**\n\n"
                    "Too many requests to OpenAI API in a short time.\n\n"
                    "**To fix:** Wait a few seconds and try again.\n"
                )
            else:
                return (
                    f"❌ **Service Error**\n\n"
                    f"The AI service encountered an issue:\n\n"
                    f"```\n{error_msg}\n```\n\n"
                    f"Please check your API configuration and try again.\n"
                )
    
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
    
    def clear_history(self) -> None:
        """Clear the conversation history to start a fresh conversation."""
        self.chat_history = ChatHistory()
        logger.info("Chat history cleared")
    
    def get_conversation_history(self) -> dict:
        """
        Get the current conversation history.
        
        Returns:
            Dictionary with 'messages' list containing all chat messages
        """
        return {
            "messages": [
                {
                    "role": msg.role.value if hasattr(msg.role, "value") else str(msg.role),
                    "content": msg.content,
                }
                for msg in self.chat_history.messages
            ]
        }

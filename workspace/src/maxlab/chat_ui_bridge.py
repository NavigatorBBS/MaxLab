"""
Chat UI Bridge: Jupyter comm interface for JupyterLab chat sidebar plugin.

Manages the NotebookChatAgent instance, handles comm messages from the frontend,
and persists conversation history to disk.
"""

import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional

from ipykernel.comm import Comm
from IPython.display import display

from maxlab.chatbot_agent import NotebookChatAgent
from maxlab.plugins.notebook_analyzer import NotebookAnalyzerPlugin
from maxlab.plugins.finance import FinancePlugin

logger = logging.getLogger(__name__)

# Global session manager instance
_session_manager: Optional["ChatSessionManager"] = None


class ChatSessionManager:
    """
    Manages a single NotebookChatAgent instance and conversation history.
    
    Responsibilities:
    - Create and manage agent lifecycle
    - Load/save history from disk
    - Handle async chat requests
    - Manage Jupyter comm communication
    """

    def __init__(
        self,
        model_id: str = "gpt-4o",
        api_key: Optional[str] = None,
        history_file: Optional[Path] = None,
    ):
        """
        Initialize the chat session manager.
        
        Args:
            model_id: OpenAI model identifier
            api_key: OpenAI API key (if None, uses env var)
            history_file: Path to chat history JSON (auto-creates .maxlab dir if None)
        """
        self.model_id = model_id
        self.api_key = api_key
        self.history_file = history_file or Path.cwd().parent / ".maxlab" / "chat_history.json"
        self.history_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Initialize agent
        try:
            self.agent = NotebookChatAgent(model_id=model_id, api_key=api_key)
            self.add_default_plugins()
            logger.info("NotebookChatAgent initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize NotebookChatAgent: {e}")
            raise
        
        # Load existing history
        self.history = self._load_history()
        self._populate_agent_history()
        
        logger.info(f"ChatSessionManager initialized. History file: {self.history_file}")
    
    def add_default_plugins(self) -> None:
        """Register default plugins with the agent."""
        try:
            self.agent.add_plugin(NotebookAnalyzerPlugin(), "notebook_analyzer")
            logger.info("NotebookAnalyzerPlugin registered")
        except Exception as e:
            logger.warning(f"Failed to register NotebookAnalyzerPlugin: {e}")
        
        try:
            self.agent.add_plugin(FinancePlugin(), "finance")
            logger.info("FinancePlugin registered")
        except Exception as e:
            logger.warning(f"Failed to register FinancePlugin: {e}")
    
    def _load_history(self) -> list:
        """
        Load conversation history from disk.
        
        Returns:
            List of {role, content, timestamp} dicts, or empty list if file missing
        """
        if self.history_file.exists():
            try:
                with open(self.history_file, "r", encoding="utf-8") as f:
                    history = json.load(f)
                    logger.info(f"Loaded {len(history)} messages from history file")
                    return history
            except (json.JSONDecodeError, IOError) as e:
                logger.error(f"Failed to load history file: {e}")
                return []
        return []
    
    def _save_history(self) -> None:
        """Persist conversation history to disk."""
        try:
            with open(self.history_file, "w", encoding="utf-8") as f:
                json.dump(self.history, f, indent=2, ensure_ascii=False)
            logger.debug(f"History saved ({len(self.history)} messages)")
        except IOError as e:
            logger.error(f"Failed to save history: {e}")
    
    def _populate_agent_history(self) -> None:
        """
        Populate agent's ChatHistory from disk history.
        
        This ensures multi-turn context is restored when session manager is created.
        """
        self.agent.clear_history()
        for msg in self.history:
            if msg.get("role") == "user":
                self.agent.chat_history.add_user_message(msg.get("content", ""))
            elif msg.get("role") == "assistant":
                self.agent.chat_history.add_assistant_message(msg.get("content", ""))
    
    async def handle_message(self, message: dict) -> dict:
        """
        Process an incoming message from the frontend and return a response.
        
        Args:
            message: Dict with 'type' and optional data fields
                     Types: "chat", "load_history", "clear_history"
        
        Returns:
            Dict with 'type', 'status', and optional 'content'/'history' fields
        """
        msg_type = message.get("type", "unknown")
        
        try:
            if msg_type == "chat":
                return await self._handle_chat(message)
            elif msg_type == "load_history":
                return self._handle_load_history()
            elif msg_type == "clear_history":
                return self._handle_clear_history()
            else:
                return {"type": "error", "status": "unknown_message_type", "content": msg_type}
        
        except Exception as e:
            logger.error(f"Error handling message type '{msg_type}': {e}")
            return {
                "type": "error",
                "status": "internal_error",
                "content": str(e),
            }
    
    async def _handle_chat(self, message: dict) -> dict:
        """
        Handle a chat message: send to agent and save history.
        
        Args:
            message: Dict with 'content' field
        
        Returns:
            Dict with 'type': "response", 'content': response text, 'timestamp': ISO8601
        """
        user_message = message.get("content", "").strip()
        
        if not user_message:
            return {"type": "error", "status": "empty_message"}
        
        # Append user message to history
        timestamp = datetime.utcnow().isoformat()
        self.history.append({
            "role": "user",
            "content": user_message,
            "timestamp": timestamp,
        })
        
        try:
            # Send to agent
            response = await self.agent.chat(user_message)
            
            # Append assistant response to history
            response_timestamp = datetime.utcnow().isoformat()
            self.history.append({
                "role": "assistant",
                "content": response,
                "timestamp": response_timestamp,
            })
            
            # Save to disk
            self._save_history()
            
            return {
                "type": "response",
                "content": response,
                "timestamp": response_timestamp,
            }
        
        except Exception as e:
            logger.error(f"Agent chat failed: {e}")
            # Remove the user message we added since agent failed
            self.history.pop()
            return {
                "type": "error",
                "status": "agent_error",
                "content": f"Agent failed to respond: {e}",
            }
    
    def _handle_load_history(self) -> dict:
        """
        Return the current conversation history.
        
        Returns:
            Dict with 'type': "history", 'history': list of messages
        """
        return {
            "type": "history",
            "history": self.history,
        }
    
    def _handle_clear_history(self) -> dict:
        """
        Clear conversation history and reset the agent.
        
        Returns:
            Dict with 'type': "cleared"
        """
        self.history.clear()
        self.agent.clear_history()
        self._save_history()
        logger.info("Chat history cleared")
        return {"type": "cleared"}


def get_session_manager(
    model_id: str = "gpt-4o",
    api_key: Optional[str] = None,
) -> ChatSessionManager:
    """
    Get or create the global ChatSessionManager singleton.
    
    Args:
        model_id: OpenAI model identifier
        api_key: OpenAI API key
    
    Returns:
        ChatSessionManager instance
    """
    global _session_manager
    if _session_manager is None:
        _session_manager = ChatSessionManager(model_id=model_id, api_key=api_key)
    return _session_manager


def init_comm_target() -> None:
    """
    Initialize the Jupyter comm target for chat UI communication.
    
    This function should be called once per kernel session to set up
    the message handler for the JupyterLab chat sidebar plugin.
    
    Usage (from a notebook cell):
        from maxlab.chat_ui_bridge import init_comm_target
        init_comm_target()
    """
    from IPython.display import display, Javascript
    import os
    
    def handle_comm_msg(msg):
        """Handle incoming comm messages from the frontend."""
        data = msg.get("content", {}).get("data", {})
        session_manager = get_session_manager()
        
        # Run async handler in the current event loop
        try:
            # Try to get the running loop (Python 3.10+)
            loop = asyncio.get_running_loop()
        except RuntimeError:
            # Create a new loop if none is running
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        # Handle the message
        response = loop.run_until_complete(session_manager.handle_message(data))
        
        # Send response back to frontend
        msg["comm"].send(response)
    
    def open_comm(comm, msg):
        """Called when frontend opens a comm."""
        logger.info("Chat UI comm opened")
        comm.on_msg(handle_comm_msg)
        
        # Send initialization confirmation
        comm.send({"type": "initialized"})
    
    # Register the comm target
    try:
        from IPython import get_ipython
        
        ipython = get_ipython()
        if ipython and hasattr(ipython, 'kernel'):
            ipython.kernel.comm_manager.register_target("maxlab_chat", open_comm)
            logger.info("Comm target 'maxlab_chat' registered")
        else:
            logger.error("IPython kernel not available")
    except Exception as e:
        logger.error(f"Failed to register comm target: {e}")


# For quick access in notebooks
async def demo_chat():
    """
    Quick demo: initialize session manager and run a test chat.
    
    Usage (from a notebook cell):
        from maxlab.chat_ui_bridge import demo_chat
        await demo_chat()
    """
    manager = get_session_manager()
    print("🤖 Chat Session Manager initialized!")
    print(f"   Model: {manager.model_id}")
    print(f"   History file: {manager.history_file}")
    print(f"   Loaded messages: {len(manager.history)}")
    
    # Send a test message
    response = await manager.agent.chat("Hello! What plugins do you have access to?")
    print(f"\n👤 User: Hello! What plugins do you have access to?")
    print(f"🤖 Agent: {response}")
    
    # Append to history manually for demo
    manager.history.append({
        "role": "user",
        "content": "Hello! What plugins do you have access to?",
        "timestamp": datetime.utcnow().isoformat(),
    })
    manager.history.append({
        "role": "assistant",
        "content": response,
        "timestamp": datetime.utcnow().isoformat(),
    })
    manager._save_history()

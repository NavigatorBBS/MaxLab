"""
Example usage of NotebookChatAgent with GitHub Copilot SDK.

This demonstrates:
1. Basic chat interaction
2. Registering custom tools using @define_tool
3. Proper lifecycle management
4. Session cleanup
"""

import asyncio
from pydantic import BaseModel, Field
from copilot import define_tool

from maxbot.chatbot_agent import NotebookChatAgent


# Example 1: Define a custom tool using @define_tool decorator
class AnalyzeCodeParams(BaseModel):
    """Parameters for code analysis tool."""
    code: str = Field(description="Python code to analyze")
    context: str = Field(default="", description="Optional context about the code")


@define_tool(description="Analyze Python code for quality and best practices")
async def analyze_code_tool(params: AnalyzeCodeParams) -> str:
    """
    Custom tool for code analysis.
    
    This would integrate with your actual analysis logic.
    """
    analysis = f"Analyzing code ({len(params.code)} characters)"
    if params.context:
        analysis += f" with context: {params.context}"
    
    # Your actual analysis logic here
    return analysis


# Example 2: Financial analysis tool
class CategorizeTransactionParams(BaseModel):
    """Parameters for transaction categorization."""
    description: str = Field(description="Transaction description")
    amount: float = Field(description="Transaction amount")


@define_tool(description="Categorize a financial transaction")
async def categorize_transaction(params: CategorizeTransactionParams) -> str:
    """
    Categorize a transaction based on description and amount.
    """
    # Your categorization logic here
    category = "Unknown"
    
    if "grocery" in params.description.lower() or "food" in params.description.lower():
        category = "Groceries"
    elif "gas" in params.description.lower() or "fuel" in params.description.lower():
        category = "Transportation"
    
    return f"Transaction '{params.description}' (${params.amount}) categorized as: {category}"


async def main():
    """Demonstrate usage of NotebookChatAgent."""
    
    # Initialize agent
    agent = NotebookChatAgent(model="gpt-4o")
    
    try:
        # Example 1: Simple chat without tools
        print("=" * 60)
        print("Example 1: Basic Chat")
        print("=" * 60)
        
        response = await agent.chat("What's the best way to optimize pandas operations?")
        print(response)
        
        # Example 2: Create a new agent with custom tools
        print("\n" + "=" * 60)
        print("Example 2: Chat with Custom Tools")
        print("=" * 60)
        
        # For tools, create a new agent and pass tools at session creation
        # Note: In the current implementation, you'd need to modify the agent
        # to accept tools in __init__ or add a method to set tools before first use
        
        agent_with_tools = NotebookChatAgent(model="gpt-4o")
        
        # Add tools before first chat (they'll be registered at session creation)
        agent_with_tools.tools = [analyze_code_tool, categorize_transaction]
        
        response = await agent_with_tools.chat(
            "Can you analyze this code and categorize a transaction for 'Whole Foods $85.32'?"
        )
        print(response)
        
        # Example 3: Get conversation history
        print("\n" + "=" * 60)
        print("Example 3: Get Messages")
        print("=" * 60)
        
        messages = await agent.get_messages()
        print(f"Conversation has {len(messages)} messages")
        
        # Example 4: Clear history and start fresh
        print("\n" + "=" * 60)
        print("Example 4: Clear History")
        print("=" * 60)
        
        await agent.clear_history()
        print("History cleared - starting fresh conversation")
        
        response = await agent.chat("Hello! What can you help me with?")
        print(response)
        
    finally:
        # Always cleanup resources
        await agent.cleanup()
        if 'agent_with_tools' in locals():
            await agent_with_tools.cleanup()
        print("\n✅ Cleanup complete")


# For Jupyter notebook usage:
async def jupyter_example():
    """
    Example usage in a Jupyter notebook.
    
    In a notebook cell:
    
    ```python
    from dotenv import load_dotenv
    load_dotenv()
    
    %load_ext maxbot
    
    # Basic usage
    response = await agent.chat("Analyze my pandas code")
    response  # Auto-displays as markdown
    
    # Clear history
    await agent.clear_history()
    
    # Get messages
    messages = await agent.get_messages()
    
    # Cleanup when done
    await agent.cleanup()
    ```
    """
    pass


if __name__ == "__main__":
    # Run the async main function
    asyncio.run(main())

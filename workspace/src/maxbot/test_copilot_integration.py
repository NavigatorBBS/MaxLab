"""
Quick test to verify GitHub Copilot SDK integration.

Run with: python -m pytest test_copilot_integration.py -v
Or: python workspace/src/maxbot/test_copilot_integration.py
"""

import asyncio
import os

try:
    import pytest
    HAS_PYTEST = True
except ImportError:
    HAS_PYTEST = False
    # Mock pytest for standalone execution
    class pytest:
        @staticmethod
        def fail(msg):
            raise AssertionError(msg)
        
        class mark:
            @staticmethod
            def skipif(condition, reason):
                def decorator(func):
                    return func
                return decorator


class TestCopilotSDKIntegration:
    """Test that the NotebookChatAgent properly uses GitHub Copilot SDK."""
    
    def test_imports(self):
        """Verify all imports work correctly."""
        try:
            from copilot import CopilotClient, define_tool
            from pydantic import BaseModel, Field
            from maxbot.chatbot_agent import NotebookChatAgent, MarkdownResponse
            print("✅ All imports successful")
        except ImportError as e:
            pytest.fail(f"Import failed: {e}")
    
    def test_agent_initialization(self):
        """Test agent can be initialized with proper parameters."""
        from maxbot.chatbot_agent import NotebookChatAgent
        
        # Mock token for testing
        os.environ["GITHUB_COPILOT_PAT"] = "test-token-for-initialization"
        
        try:
            agent = NotebookChatAgent(model="gpt-4o")
            assert agent.model == "gpt-4o"
            assert agent.system_prompt is not None
            assert agent.session is None  # Not initialized yet
            print("✅ Agent initialization successful")
        except Exception as e:
            pytest.fail(f"Agent initialization failed: {e}")
    
    def test_markdown_response(self):
        """Test MarkdownResponse class."""
        from maxbot.chatbot_agent import MarkdownResponse
        
        response = MarkdownResponse("**Hello** World")
        assert str(response) == "**Hello** World"
        assert response._repr_markdown_() == "**Hello** World"
        print("✅ MarkdownResponse works correctly")
    
    @pytest.mark.skipif(
        not os.getenv("GITHUB_COPILOT_PAT"),
        reason="GITHUB_COPILOT_PAT not set - skipping live test"
    )
    def test_live_chat(self):
        """
        Test actual chat with GitHub Copilot SDK.
        
        Only runs if GITHUB_COPILOT_PAT is set.
        """
        async def run_test():
            from maxbot.chatbot_agent import NotebookChatAgent
            
            agent = NotebookChatAgent(model="gpt-4o")
            
            try:
                # Simple chat test
                response = await agent.chat("Say 'Hello World' in markdown")
                assert isinstance(response, str)
                assert len(response) > 0
                print(f"✅ Live chat successful: {response[:50]}...")
                
                # Get messages
                messages = await agent.get_messages()
                assert isinstance(messages, list)
                print(f"✅ Got {len(messages)} messages from session")
                
            finally:
                await agent.cleanup()
                print("✅ Cleanup successful")
        
        asyncio.run(run_test())


def run_manual_test():
    """
    Manual test function - run this directly if you have GITHUB_COPILOT_PAT set.
    
    Usage: python workspace/src/maxbot/test_copilot_integration.py
    """
    print("=" * 60)
    print("GitHub Copilot SDK Integration Test")
    print("=" * 60)
    
    # Check environment
    if not os.getenv("GITHUB_COPILOT_PAT"):
        print("\n❌ GITHUB_COPILOT_PAT not set")
        print("Set it in your environment or .env file to run live tests")
        print("\nRunning basic tests only...\n")
    else:
        print("\n✅ GITHUB_COPILOT_PAT found\n")
    
    # Run basic tests
    test = TestCopilotSDKIntegration()
    
    try:
        test.test_imports()
    except Exception as e:
        print(f"❌ Import test failed: {e}")
        return
    
    try:
        test.test_agent_initialization()
    except Exception as e:
        print(f"❌ Initialization test failed: {e}")
        return
    
    try:
        test.test_markdown_response()
    except Exception as e:
        print(f"❌ MarkdownResponse test failed: {e}")
        return
    
    print("\n" + "=" * 60)
    print("Basic Tests Complete!")
    print("=" * 60)
    
    # Run live test if token is available
    if os.getenv("GITHUB_COPILOT_PAT"):
        print("\nRunning live chat test...\n")
        try:
            test.test_live_chat()
            print("\n✅ All tests passed!")
        except Exception as e:
            print(f"\n❌ Live test failed: {e}")
            import traceback
            traceback.print_exc()
    else:
        print("\n💡 To test live chat, set GITHUB_COPILOT_PAT environment variable")


if __name__ == "__main__":
    run_manual_test()

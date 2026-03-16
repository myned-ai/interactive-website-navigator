"""
Agents Package

Provides modular agent implementations for conversational AI.
Supports both local sample agents and remote (inter-container) agents.

Sample Agents:
- SampleGeminiAgent: Uses Google Gemini Live API

Remote Agent:
- RemoteAgent: Connects to external agent services via WebSocket
"""

from .base_agent import BaseAgent, ConversationState
from .gemini import SampleGeminiAgent
from .remote_agent import RemoteAgent

__all__ = [
    "BaseAgent",
    "ConversationState",
    "RemoteAgent",
    "SampleGeminiAgent",
]

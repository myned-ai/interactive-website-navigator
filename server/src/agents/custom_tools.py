"""
Domain-specific actions (Tools) for custom use cases.
These tools extend the core AI capabilities for specific use cases.
"""

GEMINI_CUSTOM_ACTIONS = [
    {
        "name": "rotate_3d_model",
        "description": (
            "Rotate the 3D product model in the viewer to show a specific angle.\n"
            "**Invocation Condition:** Invoke this tool ONLY when the user asks to see the back, side, "
            "top, or bottom of the product, or explicitly asks to rotate it, AND the most recent "
            "'viewing_product' event has `has3dModel: true`. If `has3dModel` is false or missing, "
            "do NOT call this tool."
        ),
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "direction": {
                    "type": "STRING",
                    "enum": ["left", "right", "up", "down", "front", "back"],
                    "description": "The direction to rotate the 3D model."
                }
            },
            "required": ["direction"]
        }
    }
]

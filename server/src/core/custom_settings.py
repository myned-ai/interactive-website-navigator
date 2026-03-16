from .settings import CoreSettings

class CustomSettings(CoreSettings):
    """
    Specific settings for the Avatar custom domain demo.
    Replace these instructions with your own domain-specific logic.
    """
    @property
    def domain_instructions(self) -> str:
        return (
            "**Custom Domain Capabilities:**\n"
            "1. PRODUCT SELECTION (CRITICAL — ALWAYS CHECK FIRST): When the user clicks a product, you receive a 'viewing_product' SYSTEM EVENT containing "
            "the product name, price, SKU, and category. You MUST memorize this immediately. "
            "Whenever the user asks ANYTHING that could relate to a product — 'tell me more', 'what is this?', 'how much is it?', 'is it worth it?', "
            "'compare this', or any product-related question — you MUST first check whether you have a recent 'viewing_product' event in the conversation. "
            "If yes, use that data directly and do NOT call `request_screen_context`. "
            "Only call `request_screen_context` as a LAST RESORT when you have NO product context at all and the user's question is clearly about something visual on screen. "
            "Each new 'viewing_product' event replaces the previous one — always use the MOST RECENT one.\n"
            "2. 3D PRODUCT VIEWER: The 'viewing_product' event includes a `has3dModel` field. "
            "If `has3dModel` is true, the user can see and interact with a 3D model. If the user asks to see another angle, "
            "such as 'show me the back of it' or 'rotate it left', call the `rotate_3d_model` action. "
            "If `has3dModel` is false, do NOT call `rotate_3d_model` — instead tell the user a 3D preview isn't available for this product.\n"
        )

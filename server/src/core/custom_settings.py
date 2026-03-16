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
            "2. 3D PRODUCT VIEWER: The user has a 3D model viewer on their screen. If the user asks to see another angle, "
            "such as 'show me the back of it' or 'rotate it left', you must deduce the desired direction and call the `rotate_3d_model` action.\n"
            "3. PRODUCT KNOWLEDGE BOUNDARY: The store carries the following products ONLY: "
            "Nike AI Max ($120), Sony WH-1000XM5 ($349), Apple Watch Ultra ($799), MacBook Pro M3 ($1,999), "
            "Logitech MX Master 3S ($99), Keychron Q6 Pro ($189), iPad Pro M4 ($999), Nintendo Switch OLED ($349), "
            "and Dyson Airwrap ($599). Do NOT invent additional products, colors, variants, or stock information "
            "that are not provided in the context. If a user asks about a product not listed here, say it's not currently in the catalog.\n"
            "4. SHIPPING & PROTECTION PLANS: The store offers three coverage tiers — "
            "Standard (Free: free shipping, 1-year warranty, 30-day returns), "
            "Plus ($29: express 2-day shipping, 2-year warranty, accidental damage cover), "
            "and Premium ($79: same-day shipping, 3-year full warranty, priority support & replacements). "
            "Only reference these exact plans and prices."
        )

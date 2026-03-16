# Website-Navigator-Client!!

**Embeddable 3D Avatar Chat Widget** - Real-time Voice & Text Chat with Gaussian Splatting Avatar Animation.

> **Next-Gen Engagement:** Replace static chatbots with a living, breathing 3D avatar that talks to your visitors.

## ✨ Features

- **Hyper-Realistic 3D Avatars**: Powered by **3D Gaussian Splatting** for cinematic visual fidelity directly in the browser.
- **Precise Lip-Sync**: Animation tightly synchronized with audio for a lifelike experience.
- **Natural Voice Interaction**: Full duplex voice chat with echo cancellation and noise suppression.
- **Zero-Conflict styles**: Fully encapsulated using **Shadow DOM** – never breaks your site's layout.
- **Smart Loading**: Lazy-loaded 3D engine ensures your initial page load remains instant.
- **100% Customizable**: Change suggestions, colors, and behaviors via simple config.

---

## Quick Start

```bash
npm install
npm run dev
```

This starts the demo site (`index.html`) — a full-featured page with the avatar widget loaded locally from `./src/widget.ts`. Make sure the [server](../server/README.md) is running on `ws://localhost:8080/ws`.

---

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `container` | `string \| HTMLElement` | **required** | CSS selector or DOM element |
| `serverUrl` | `string` | **required** | WebSocket server URL (ws:// or wss://) |
| `position` | `string` | `'bottom-right'` | `bottom-right`, `bottom-left`, `top-right`, `top-left`, `inline` |
| `primaryColor` | `string` | `'#4B4ACF'` | Main brand color (hex, rgb, etc) |
| `suggestions` | `string[]` | `['...']` | Array of quick-reply suggestions |
| `startCollapsed` | `boolean` | `true` | Start minimized as bubble |
| `tooltipText` | `string` | `'Hi! 👋...'` | Text shown on bubble hover |
| `width` | `number` | `380` | Widget width (200-2000px) |
| `height` | `number` | `550` | Widget height (300-2000px) |
| `enableVoice` | `boolean` | `true` | Enable voice chat |
| `enableText` | `boolean` | `true` | Enable text chat |
| `authEnabled` | `boolean` | `false` | Enable HMAC authentication |
| `avatarUrl` | `string` | auto-detected | URL to avatar ZIP file |
| `assetsBaseUrl` | `string` | auto-detected | Base URL for worklet/assets |
| `customStyles` | `string` | `undefined` | Custom CSS to inject into Shadow DOM |
| `logLevel` | `string` | `'error'` | `none`, `error`, `warn`, `info`, `debug` |

### Callbacks

| Callback | Type | Description |
|----------|------|-------------|
| `onReady` | `() => void` | Widget initialized and ready |
| `onConnectionChange` | `(connected: boolean) => void` | WebSocket connection status changed |
| `onMessage` | `(msg: {role, text}) => void` | Message received from server |
| `onError` | `(error: Error) => void` | Error occurred |

---

## Customization

### Quick Branding

For simple color matching, use the `primaryColor` option:

```typescript
AvatarChat.init({
  container: '#avatar-chat',
  serverUrl: 'wss://...',
  primaryColor: '#FF5722', // Match your brand
  secondaryColor: '#37474F'
});
```

### Advanced Styling

For deeper customization, use the `customStyles` option to inject CSS directly into the widget's Shadow DOM:

```typescript
AvatarChat.init({
  container: '#avatar-chat',
  serverUrl: 'wss://your-server.com/ws',
  customStyles: `
    /* Primary brand colors (gradient, buttons, user messages) */
    .chat-bubble,
    .chat-header {
      background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%) !important;
    }

    .input-button {
      background: #ff6b6b !important;
    }

    .input-button:hover:not(:disabled) {
      background: #ee5a6f !important;
    }

    .message.user .message-bubble {
      background: #ff6b6b !important;
    }

    /* Avatar border */
    .avatar-circle {
      border-color: #ff6b6b !important;
    }

    /* Input focus color */
    #chatInput:focus {
      border-color: #ff6b6b !important;
    }
  `
});
```

**Common color targets:**
- `.chat-bubble` - Minimized bubble
- `.chat-header` - Header gradient
- `.avatar-circle` - Avatar border
- `.input-button` - Send & mic buttons
- `.message.user .message-bubble` - User message bubbles
- `#chatInput:focus` - Input field focus state

---

## WebSocket Protocol

### Client → Server

```json
{ "type": "text", "data": "Hello", "userId": "user_123", "timestamp": 1234567890 }
{ "type": "audio", "data": "<ArrayBuffer>", "format": "audio/webm" }
```

### Server → Client

```json
{ "type": "audio_start", "sessionId": "abc", "sampleRate": 24000 }
{ "type": "audio_chunk", "data": "<ArrayBuffer>", "timestamp": 1234567890 }
{ "type": "blendshape", "weights": {...}, "timestamp": 1234567890 }
{ "type": "audio_end", "sessionId": "abc" }
{ "type": "text", "data": "Hello", "timestamp": 1234567890 }
```

---

## Authentication

### Disabling Auth (Development)

For local testing without an auth server:

```typescript
AvatarChat.init({
  container: '#avatar-chat',
  serverUrl: 'ws://localhost:8080/ws',
  authEnabled: false  // Disable authentication
});
```

### Production Setup

The widget uses HMAC-SHA256 token authentication for secure connections:

1. Widget requests token from `POST /api/auth/token`
2. Server validates origin and returns signed token
3. Widget connects with token: `wss://server/ws?token=...`
4. Server verifies signature and expiration

**Security features:**
- Origin validation (whitelist domains)
- Time-limited tokens with auto-refresh
- Rate limiting per domain/session

---

## Development

### Local Setup

```bash
# Install dependencies
npm install

# Start dev server with hot reload
npm run dev

# Build for production
npm run build:lib
```

### Testing with Backend

```bash
# From the repo root, start the server
cd ../server
cp .env.example .env
# Edit .env: set GEMINI_USE_VERTEX=false, GEMINI_API_KEY, AUTH_ENABLED=false

# With Docker
docker-compose up -d

# Or without Docker
uv sync && uv run python src/main.py
```

Server runs on `ws://localhost:8080/ws`. See [server/README.md](../server/README.md) for full setup details.

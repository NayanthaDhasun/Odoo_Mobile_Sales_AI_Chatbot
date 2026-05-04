<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title> Business Analytics Assistant</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
        href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=Inter:wght@400;500;600&display=swap"
        rel="stylesheet">

    <!-- Marked.js for Markdown parsing -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>

    <style>
        :root {
            --bg-base: #030712;
            --bg-surface: #0B0F19;
            --bg-surface-raised: #111827;
            --text-primary: #F8FAFC;
            --text-secondary: #94A3B8;
            --border-subtle: rgba(255, 255, 255, 0.08);
            --border-focus: #3B82F6;
            --brand-primary: #2563EB;
            --brand-primary-hover: #3B82F6;
            --accent-glow: rgba(59, 130, 246, 0.15);

            --radius-sm: 8px;
            --radius-md: 12px;
            --radius-lg: 16px;
            --radius-full: 9999px;

            --font-heading: 'Outfit', sans-serif;
            --font-body: 'Inter', sans-serif;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: var(--font-body);
            background-color: var(--bg-base);
            color: var(--text-primary);
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            overflow: hidden;
            background-image:
                radial-gradient(circle at 15% 50%, rgba(37, 99, 235, 0.08) 0%, transparent 50%),
                radial-gradient(circle at 85% 30%, rgba(139, 92, 246, 0.08) 0%, transparent 50%);
        }

        /* Ambient Glow Behind Chat */
        .ambient-glow {
            position: absolute;
            width: 70vw;
            height: 70vh;
            background: radial-gradient(circle, var(--accent-glow) 0%, transparent 70%);
            z-index: 0;
            pointer-events: none;
        }

        .dashboard-container {
            width: 100%;
            max-width: 1000px;
            height: 90vh;
            max-height: 850px;
            background: var(--bg-surface);
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-lg);
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.05);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            z-index: 10;
            position: relative;
        }

        /* --- Header --- */
        .chat-header {
            padding: 24px 32px;
            border-bottom: 1px solid var(--border-subtle);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: rgba(11, 15, 25, 0.8);
            backdrop-filter: blur(12px);
            z-index: 20;
        }

        .header-title {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .header-icon {
            width: 32px;
            height: 32px;
            background: linear-gradient(135deg, #3B82F6, #8B5CF6);
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
        }

        .header-title h2 {
            font-family: var(--font-heading);
            font-size: 20px;
            font-weight: 600;
            letter-spacing: -0.02em;
        }

        .header-status {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            color: var(--text-secondary);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            background: #10B981;
            border-radius: 50%;
            box-shadow: 0 0 8px #10B981;
        }

        /* --- Messages Area --- */
        .messages-area {
            flex: 1;
            overflow-y: auto;
            padding: 32px;
            display: flex;
            flex-direction: column;
            gap: 24px;
            scroll-behavior: smooth;
        }

        .message {
            display: flex;
            gap: 16px;
            animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
            opacity: 0;
            transform: translateY(10px);
        }

        @keyframes slideUp {
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .message-avatar {
            width: 36px;
            height: 36px;
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            flex-shrink: 0;
        }

        .bot-message .message-avatar {
            background: var(--bg-surface-raised);
            border: 1px solid var(--border-subtle);
        }

        .user-message {
            flex-direction: row-reverse;
        }

        .user-message .message-avatar {
            background: var(--brand-primary);
        }

        .message-content-wrapper {
            max-width: 75%;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .message-sender-name {
            font-size: 12px;
            color: var(--text-secondary);
            font-weight: 500;
            margin-bottom: 2px;
        }

        .user-message .message-sender-name {
            text-align: right;
        }

        .message-bubble {
            padding: 16px 20px;
            border-radius: var(--radius-md);
            font-size: 15px;
            line-height: 1.6;
            color: var(--text-primary);
        }

        .bot-message .message-bubble {
            background: var(--bg-surface-raised);
            border: 1px solid var(--border-subtle);
            border-top-left-radius: 4px;
        }

        .user-message .message-bubble {
            background: var(--brand-primary);
            color: white;
            border-top-right-radius: 4px;
        }

        /* Markdown Styling inside Bot Bubble */
        .markdown-body {
            font-family: var(--font-body);
        }

        .markdown-body p {
            margin-bottom: 12px;
        }

        .markdown-body p:last-child {
            margin-bottom: 0;
        }

        .markdown-body strong {
            color: white;
            font-weight: 600;
        }

        .markdown-body ul,
        .markdown-body ol {
            margin-left: 20px;
            margin-bottom: 12px;
        }

        .markdown-body li {
            margin-bottom: 4px;
        }

        .markdown-body code {
            background: #1E293B;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: monospace;
            font-size: 13.5px;
            color: #E2E8F0;
        }

        /* Typing Indicator */
        .typing-bubble {
            padding: 16px 20px;
            background: var(--bg-surface-raised);
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-md);
            border-top-left-radius: 4px;
            display: inline-flex;
            gap: 4px;
            align-items: center;
            height: 56px;
            /* Match single line height approx */
        }

        .typing-dot {
            width: 6px;
            height: 6px;
            background: var(--text-secondary);
            border-radius: 50%;
            animation: bounce 1.4s infinite ease-in-out both;
        }

        .typing-dot:nth-child(1) {
            animation-delay: -0.32s;
        }

        .typing-dot:nth-child(2) {
            animation-delay: -0.16s;
        }

        @keyframes bounce {

            0%,
            80%,
            100% {
                transform: scale(0);
                opacity: 0.5;
            }

            40% {
                transform: scale(1);
                opacity: 1;
            }
        }

        /* --- Footer & Input --- */
        .chat-footer {
            padding: 24px 32px;
            background: var(--bg-surface);
            border-top: 1px solid var(--border-subtle);
        }

        .suggestions {
            display: flex;
            gap: 12px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }

        .suggestion-chip {
            padding: 8px 16px;
            background: transparent;
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-full);
            color: var(--text-secondary);
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .suggestion-chip:hover {
            border-color: var(--brand-primary);
            color: var(--text-primary);
            background: rgba(59, 130, 246, 0.05);
        }

        .input-group {
            display: flex;
            background: var(--bg-surface-raised);
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-lg);
            padding: 8px;
            transition: border-color 0.2s, box-shadow 0.2s;
        }

        .input-group:focus-within {
            border-color: var(--border-focus);
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
        }

        .input-group input {
            flex: 1;
            background: transparent;
            border: none;
            padding: 12px 16px;
            color: var(--text-primary);
            font-family: var(--font-body);
            font-size: 15px;
            outline: none;
        }

        .input-group input::placeholder {
            color: var(--text-secondary);
        }

        .input-group button {
            background: var(--brand-primary);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            padding: 0 24px;
            font-family: var(--font-heading);
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.2s;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .input-group button:hover {
            background: var(--brand-primary-hover);
        }

        /* Custom Scrollbar */
        ::-webkit-scrollbar {
            width: 8px;
        }

        ::-webkit-scrollbar-track {
            background: transparent;
        }

        ::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 4px;
        }

        ::-webkit-scrollbar-thumb:hover {
            background: rgba(255, 255, 255, 0.2);
        }
    </style>



</head>

<body>
    <div class="ambient-glow"></div>

    <div class="dashboard-container">



        <!-- Header -->
        <div class="chat-header">
            <div class="header-title">
                <div class="header-icon">📊</div>
                <div>
                    <h2>Business Analytics</h2>
                    <div class="header-status">
                        <div class="status-dot"></div>
                        <span>AI Assistant Online</span>
                    </div>
                </div>
            </div>
            <div style="color: var(--text-secondary); font-size: 13px;">
                Secured Connection
            </div>
        </div>




        <!-- Messages -->
        <div class="messages-area" id="messagesArea">
            <div class="message bot-message" style="opacity: 1; transform: translateY(0);">
                <div class="message-avatar">🤖</div>
                <div class="message-content-wrapper">
                    <div class="message-sender-name"> AI</div>
                    <div class="message-bubble markdown-body">
                        <p>Welcome to <strong> Business Analytics</strong>.</p>
                        <p>I am your enterprise data assistant connected directly to your backend. I can analyze and
                            report on:</p>
                        <ul>
                            <li>Live Product Inventory & Pricing</li>
                            <li>Sales Data Summaries</li>
                            <li>Customer Metrics</li>
                        </ul>
                        <p>How can I assist your business today?</p>
                    </div>
                </div>
            </div>
        </div>



        <!-- Footer -->
        <div class="chat-footer">
            <div class="suggestions">

<!-- Quick Suggestion Buttons 1 -->
                <button class="suggestion-chip" onclick="sendQuickMessage('Show me the top products')">
                    <span>📈</span> Top Products
                </button>

<!-- Quick Suggestion Buttons 2 -->
                <button class="suggestion-chip" onclick="sendQuickMessage('Show me the prices of the products?')">
                    <span>💲</span> Check Prices
                </button>

<!-- Quick Suggestion Buttons 3 -->
                <button class="suggestion-chip" onclick="sendQuickMessage('Give me a sales summary')">
                    <span>📊</span> Sales Summary
                </button>

                <button class="suggestion-chip" onclick="sendQuickMessage('Show me the top 3 selling items')">
                    <span>🏆</span> Top 3 Selling Items
                </button>

                <button class="suggestion-chip" onclick="sendQuickMessage('Show me sales by month')">
                    <span>📅</span> Sales by Month
                </button>

                <button class="suggestion-chip" onclick="sendQuickMessage('Show me the most purchased products')">
                    <span>🛒</span> Most Purchased Products
                </button>


            </div>

            <div class="input-group">
                <input type="text" id="messageInput" placeholder="Ask anything..." onkeypress="handleKeyPress(event)"
                    autocomplete="off">
                <button onclick="sendMessage()">
                    Send
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                        stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="22" y1="2" x2="11" y2="13"></line>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                </button>
            </div>
        </div>
    </div>

    <script>
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        // Configure marked.js to be safe if desired, or just use defaults
        marked.setOptions({
            breaks: true, // translate newlines to <br>
            gfm: true
        });

        function handleKeyPress(event) {
            if (event.key === 'Enter') {
                sendMessage();
            }
        }

        function sendQuickMessage(message) {
            document.getElementById('messageInput').value = message;
            sendMessage();
        }

        async function sendMessage() {
            const input = document.getElementById('messageInput');
            const message = input.value.trim();

            //console.log(message);

            if (!message) return;

            addMessage(message, 'user');
            input.value = '';

            showTypingIndicator();

            try {
                const response = await fetch('/odoo/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrfToken,
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        message: message
                    })
                });

                const data = await response.json();
                removeTypingIndicator();

                if (data.reply) {
                    addMessage(data.reply, 'bot');
                } else if (data.error) {
                    addMessage('**Error:** ' + data.error, 'bot');
                } else {
                    addMessage('**Error:** Sorry, no response received.', 'bot');
                }

            } catch (error) {
                removeTypingIndicator();
                addMessage('**Connection Error:** Failed to securely connect to Odoo services.', 'bot');
               
            }
        }

        function addMessage(text, type) {
            const messagesArea = document.getElementById('messagesArea');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${type}-message`;

            // Avatar
            const avatarDiv = document.createElement('div');
            avatarDiv.className = 'message-avatar';
            avatarDiv.innerHTML = type === 'bot' ? '🤖' : '👤';

            // Wrapper
            const wrapperDiv = document.createElement('div');
            wrapperDiv.className = 'message-content-wrapper';

            // Sender Name
            const nameDiv = document.createElement('div');
            nameDiv.className = 'message-sender-name';
            nameDiv.innerText = type === 'bot' ? 'AI' : 'You';

            // Bubble
            const bubbleDiv = document.createElement('div');
            bubbleDiv.className = `message-bubble ${type === 'bot' ? 'markdown-body' : ''}`;

            if (type === 'bot') {
                // Parse markdown for bot messages
                bubbleDiv.innerHTML = marked.parse(text);
            } else {
                // Plain text for user (just escape HTML and add line breaks)
                bubbleDiv.innerText = text;
            }

            wrapperDiv.appendChild(nameDiv);
            wrapperDiv.appendChild(bubbleDiv);

            messageDiv.appendChild(avatarDiv);
            messageDiv.appendChild(wrapperDiv);

            messagesArea.appendChild(messageDiv);
            messagesArea.scrollTop = messagesArea.scrollHeight;
        }

        function showTypingIndicator() {
            const messagesArea = document.getElementById('messagesArea');

            const typingDiv = document.createElement('div');
            typingDiv.id = 'typingIndicator';
            typingDiv.className = 'message bot-message';

            const avatarDiv = document.createElement('div');
            avatarDiv.className = 'message-avatar';
            avatarDiv.innerHTML = '🤖';

            const wrapperDiv = document.createElement('div');
            wrapperDiv.className = 'message-content-wrapper';

            const nameDiv = document.createElement('div');
            nameDiv.className = 'message-sender-name';
            nameDiv.innerText = 'AI is analyzing...';

            const bubbleDiv = document.createElement('div');
            bubbleDiv.className = 'typing-bubble';
            bubbleDiv.innerHTML = `
                <div class="typing-dot"></div>
                <div class="typing-dot"></div>
                <div class="typing-dot"></div>
            `;

            wrapperDiv.appendChild(nameDiv);
            wrapperDiv.appendChild(bubbleDiv);

            typingDiv.appendChild(avatarDiv);
            typingDiv.appendChild(wrapperDiv);

            messagesArea.appendChild(typingDiv);
            messagesArea.scrollTop = messagesArea.scrollHeight;
        }

        function removeTypingIndicator() {
            const indicator = document.getElementById('typingIndicator');
            if (indicator) {
                indicator.remove();
            }
        }
    </script>
</body>

</html>

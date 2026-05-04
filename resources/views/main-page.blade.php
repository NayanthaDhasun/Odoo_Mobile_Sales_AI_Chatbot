<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Business Assistant Bot</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg-base: #030712;
            --bg-surface: #0B0F19;
            --bg-surface-raised: #111827;
            --text-primary: #F8FAFC;
            --text-secondary: #94A3B8;
            --border-subtle: rgba(255, 255, 255, 0.08);
            --brand-primary: #2563EB;
            --brand-primary-hover: #3B82F6;
            --accent-glow: rgba(59, 130, 246, 0.15);

            --radius-md: 12px;
            --radius-lg: 16px;

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

        /* Ambient Glow Behind Container */
        .ambient-glow {
            position: absolute;
            width: 70vw;
            height: 70vh;
            background: radial-gradient(circle, var(--accent-glow) 0%, transparent 70%);
            z-index: 0;
            pointer-events: none;
        }

        .welcome-container {
            width: 100%;
            max-width: 500px;
            padding: 48px;
            background: var(--bg-surface);
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-lg);
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.05);
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            z-index: 10;
            position: relative;
        }

        .icon-container {
            width: 64px;
            height: 64px;
            background: linear-gradient(135deg, #3B82F6, #8B5CF6);
            border-radius: var(--radius-lg);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            box-shadow: 0 4px 20px rgba(59, 130, 246, 0.4);
            margin-bottom: 24px;
        }

        h1 {
            font-family: var(--font-heading);
            font-size: 32px;
            font-weight: 600;
            letter-spacing: -0.02em;
            margin-bottom: 12px;
        }

        p {
            color: var(--text-secondary);
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 32px;
        }

        .start-btn {
            background: var(--brand-primary);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            padding: 16px 32px;
            font-family: var(--font-heading);
            font-weight: 600;
            font-size: 16px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 12px;
            text-decoration: none;
            width: 100%;
            justify-content: center;
        }

        .start-btn:hover {
            background: var(--brand-primary-hover);
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(59, 130, 246, 0.25);
        }

        .start-btn svg {
            transition: transform 0.2s;
        }

        .start-btn:hover svg {
            transform: translateX(4px);
        }

    </style>
</head>

<body>
    <div class="ambient-glow"></div>

    <div class="welcome-container">
        <div class="icon-container">📊</div>
        <h1>Business Assistant</h1>
        <p>Your enterprise data assistant connected directly to your backend. Analyze live product inventory, sales data, and customer metrics.</p>
        
        <a href="{{ route('chat') }}" style="width: 100%; text-decoration: none;">
            <button class="start-btn">
                Start Chatting
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                    <polyline points="12 5 19 12 12 19"></polyline>
                </svg>
            </button>
        </a>
    </div>

</body>

</html>
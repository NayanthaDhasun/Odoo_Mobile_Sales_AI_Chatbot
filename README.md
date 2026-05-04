# Odoo Mobile Sales AI Chatbot

A Laravel-based AI chatbot that connects to your Odoo ERP instance and lets you query live business data through a conversational chat interface. Powered by OpenRouter AI.

## Features

- Live data fetched directly from Odoo via XML-RPC
- AI-powered natural language responses using OpenRouter
- Queries across multiple Odoo models: Products, Sales Orders, Invoices, Customers, Payments, Purchase Orders
- Aggregated insights: top selling products, top purchased products, monthly sales and invoice summaries
- Markdown rendering in the chat UI
- Quick suggestion chips for common queries

## Tech Stack

- **Backend**: Laravel 10 (PHP 8.1+)
- **Frontend**: Blade templates, Vanilla JS, Vite
- **AI**: OpenRouter API (configurable model)
- **ERP Integration**: Odoo XML-RPC API
- **Database**: MySQL (for Laravel internals)

## Requirements

- PHP 8.1+
- Composer
- Node.js & npm
- MySQL
- An Odoo instance with API access
- An OpenRouter API key

## Setup

**1. Clone the repository**

```bash
git clone git@github.com:NayanthaDhasun/Odoo_Mobile_Sales_AI_Chatbot.git
cd Odoo_Mobile_Sales_AI_Chatbot
```

**2. Install dependencies**

```bash
composer install
npm install
```

**3. Configure environment**

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env` and fill in your credentials:

```env
OPENROUTER_API_KEY=your-openrouter-api-key-here

ODOO_URL=https://your-odoo-instance.odoo.com
ODOO_DB=your-odoo-database
ODOO_USERNAME=admin
ODOO_API_KEY=your-odoo-api-key-here

DB_DATABASE=your_db_name
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password
```

You can also set the AI model in `config/services.php` under `openrouter.model`.

**4. Run migrations**

```bash
php artisan migrate
```

**5. Build frontend assets**

```bash
npm run dev
```

**6. Start the server**

```bash
php artisan serve
```

Visit `http://localhost:8000` to open the app.

## Routes

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/` | Main landing page |
| GET | `/chat` | Chat interface |
| POST | `/odoo/chat` | Handles chat messages (JSON) |

## Data Sources

The chatbot fetches the following data from Odoo on each message:

| Data | Odoo Model |
|------|------------|
| Products | `product.template` |
| Sales Orders | `sale.order` |
| Sale Order Lines | `sale.order.line` |
| Invoices | `account.move` |
| Customers | `res.partner` |
| Payments | `account.payment` |
| Purchase Orders | `purchase.order` |
| Purchase Order Lines | `purchase.order.line` |

## Example Questions

- "Show me the top 5 selling products"
- "Give me a sales summary by month"
- "What are the most purchased products?"
- "Show me all unpaid invoices"
- "What is the total revenue this month?"

## License

MIT

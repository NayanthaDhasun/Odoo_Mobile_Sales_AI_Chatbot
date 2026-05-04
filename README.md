# Odoo Mobile Sales AI Chatbot

A full-stack solution for Odoo-powered businesses, consisting of two components:

1. **AI Chatbot (Web)** — A Laravel web app that lets you query live Odoo business data through a conversational AI interface
2. **Sales Management App (Mobile)** — A Flutter mobile app for managing sales, customers, orders, and inventory connected to Odoo

---

## Repository Structure

```
/                        # Laravel AI Chatbot (web)
mobile_app/              # Flutter Sales Management App (mobile)
```

---

## 1. AI Chatbot (Web)

A Laravel-based AI chatbot that connects to your Odoo ERP instance and lets you query live business data through a chat interface. Powered by OpenRouter AI.

### Features

- Live data fetched directly from Odoo via XML-RPC
- AI-powered natural language responses using OpenRouter
- Queries across multiple Odoo models: Products, Sales Orders, Invoices, Customers, Payments, Purchase Orders
- Aggregated insights: top selling products, top purchased products, monthly sales and invoice summaries
- Markdown rendering in the chat UI
- Quick suggestion chips for common queries

### Tech Stack

- **Backend**: Laravel 10 (PHP 8.1+)
- **Frontend**: Blade templates, Vanilla JS, Vite
- **AI**: OpenRouter API (configurable model)
- **ERP Integration**: Odoo XML-RPC API
- **Database**: MySQL

### Requirements

- PHP 8.1+
- Composer
- Node.js & npm
- MySQL
- An Odoo instance with API access
- An OpenRouter API key

### Setup

**1. Install dependencies**

```bash
composer install
npm install
```

**2. Configure environment**

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

**3. Run migrations and start**

```bash
php artisan migrate
npm run dev
php artisan serve
```

Visit `http://localhost:8000`

### Routes

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/` | Main landing page |
| GET | `/chat` | Chat interface |
| POST | `/odoo/chat` | Handles chat messages (JSON) |

### Odoo Data Sources

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

### Example Questions

- "Show me the top 5 selling products"
- "Give me a sales summary by month"
- "What are the most purchased products?"
- "Show me all unpaid invoices"

---

## 2. Sales Management App (Mobile)

A Flutter mobile app for sales representatives to manage customers, take orders, view inventory, and track sales — all connected to Odoo via JSON-RPC.

### Features

- Login and employee validation via Odoo
- Dashboard with sales overview
- Customer list and management
- Order taking with product selection
- Sales order list with order details
- Inventory view
- Background financial data sync

### Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: GetX
- **ERP Integration**: Odoo JSON-RPC API
- **Local Storage**: shared_preferences
- **Fonts**: Google Fonts

### Requirements

- Flutter SDK (Dart ^3.11.1)
- An Odoo instance with JSON-RPC access

### Setup

```bash
cd mobile_app
flutter pub get
flutter run
```

### App Structure

```
lib/
  api/          # JSON-RPC helper for Odoo communication
  bindings/     # GetX dependency injection bindings
  constants/    # Colors, theme, static data
  controllers/  # GetX controllers (auth, dashboard, customers, sales, orders, products)
  models/       # Data models (customer, product, sales order, order lines)
  routes/       # App routes and pages
  services/     # Background services (financial sync, validation)
  views/        # UI screens
    auth/       # Login, employee validation
    customer/   # Customer list, order taking
    dashboard/  # Dashboard
    inventory/  # Inventory view
    sales/      # Sales list, order details
```

---

## License

MIT

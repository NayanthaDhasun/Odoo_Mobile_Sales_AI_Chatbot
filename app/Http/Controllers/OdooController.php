<?php

namespace App\Http\Controllers;

use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OdooController extends Controller
{

    public function index()
    {
        try {
            // return 'Odoo-chat page not found';
     return view('odoo-chat');
        } catch (Exception $e) {
          //  return 'Odoo-chat page not found';
            return redirect()->back()->with('error', $e->getMessage());
        }
    }


    public function mainPage()
    {
        try {
            return view('main-page');
        } catch (Exception $e) {
            return 'Main page not found';
            //return redirect()->back()->with('error', $e->getMessage());
        }
    }


    public function chat(Request $request)
    {
        $userMessage = $request->input('message');

      // return $userMessage;

        if (!$userMessage) {
            return response()->json(['error' => 'Please provide a message.'], 400);
        }

        try {
            //database ture data read
            $odooData = $this->fetchOdooProducts();

            //gemini ai using data read
            $reply = $this->getAiResponse($userMessage, $odooData);

            return response()->json([
                'reply' => $reply
            ]);

            //return $reply;

        } catch (\Throwable $e) {

            //return $e->getMessage()

            return response()->json([
                'error' => 'An error occurred: ' . $e->getMessage()
            ], 500);
        }
    }


   private function fetchOdooProducts()
{
    // Link Odoo Data 
    $url = config('services.odoo.url');
    $db = config('services.odoo.db');
    $username = config('services.odoo.username');
    $apiKey = config('services.odoo.api_key');

    if (!$url || !$db || !$username || !$apiKey) {
        throw new Exception('Odoo credentials not configured in .env');
    }

    // 1. Login to get UID
    $loginXml = "<?xml version='1.0'?>
    <methodCall>
        <methodName>authenticate</methodName>
        <params>
            <param><value><string>$db</string></value></param>
            <param><value><string>$username</string></value></param>
            <param><value><string>$apiKey</string></value></param>
            <param><value><struct/></value></param>
        </params>
    </methodCall>";

    $loginResponse = Http::withHeaders(['Content-Type' => 'text/xml'])->send('POST', $url . "/xmlrpc/2/common", ['body' => $loginXml]);
    $loginResult = simplexml_load_string($loginResponse->body());

    






    if (!isset($loginResult->params->param->value->int)) {
        throw new Exception('Odoo Authentication failed');
    }
    $uid = (int) $loginResult->params->param->value->int;

    // 2. Define the different models and fields to fetch
    $queries = [
        'Products' => [
            'model' => 'product.template',
            'fields' => ['name', 'list_price', 'qty_available', 'standard_price', 'default_code'],
            'domain' => []
        ],
        'Sales_Orders' => [
            'model' => 'sale.order',
            'fields' => ['name', 'date_order', 'partner_id', 'amount_total', 'state'],
            'domain' => []
        ],
        'Sale_Order_Lines' => [
            'model' => 'sale.order.line',
            'fields' => ['product_id', 'product_uom_qty', 'qty_delivered', 'price_subtotal', 'order_id'],
            'domain' => [],
            'limit' => 1000,
        ],
        'Invoices' => [
    'model' => 'account.move',
    'fields' => [
        'name',                    
        'partner_id',              
        'invoice_date',            
        'invoice_date_due',        
        'amount_untaxed',          
        'amount_total',            
        'payment_state'           
    ],
    'domain' => []
],
        'Customers' => [
            'model' => 'res.partner',
            'fields' => ['name', 'phone', 'email', 'city'],
            'domain' => []
        ],
        'Payments' => [
            'model' => 'account.payment',
            'fields' => ['name', 'date', 'amount', 'partner_id', 'state'],
            'domain' => []
        ],
        'Purchase_Orders' => [
            'model' => 'purchase.order',
            'fields' => ['name', 'date_order', 'partner_id', 'amount_total', 'state'],
            'domain' => []
        ],
        'Purchase_Order_Lines' => [
            'model' => 'purchase.order.line',
            'fields' => ['product_id', 'product_qty', 'qty_received', 'price_unit', 'price_subtotal', 'order_id'],
            'domain' => [],
            'limit' => 1000,
        ],
    ];

    $allData = [];

    // 3. Loop through queries and fetch data
    foreach ($queries as $label => $data) {
        $domainXml = "";
        foreach ($data['domain'] as $filter) {
            $domainXml .= "<value><array><data>
                <value><string>{$filter[0]}</string></value>
                <value><string>{$filter[1]}</string></value>
                <value><string>{$filter[2]}</string></value>
            </data></array></value>";
        }

        $fieldsXml = "";
        foreach ($data['fields'] as $field) {
            $fieldsXml .= "<value><string>$field</string></value>";
        }

        $limitXml = isset($data['limit'])
            ? "<member><name>limit</name><value><int>{$data['limit']}</int></value></member>"
            : "";

        $fetchXml = "<?xml version='1.0'?>
        <methodCall>
            <methodName>execute_kw</methodName>
            <params>
                <param><value><string>$db</string></value></param>
                <param><value><int>$uid</int></value></param>
                <param><value><string>$apiKey</string></value></param>
                <param><value><string>{$data['model']}</string></value></param>
                <param><value><string>search_read</string></value></param>
                <param><value><array><data>$domainXml</data></array></value></param>
                <param><value><struct>
                    <member><name>fields</name><value><array><data>$fieldsXml</data></array></value></member>
                    $limitXml
                </struct></value></param>
            </params>
        </methodCall>";

        $response = Http::withHeaders(['Content-Type' => 'text/xml'])->send('POST', $url . "/xmlrpc/2/object", ['body' => $fetchXml]);
        
        // Parse the XML response and extract the actual data
        $parsedData = $this->parseOdooResponse($response->body(), $label);
        $allData[$label] = $parsedData;
    }

    // Convert the structured data to a readable format for the AI
    return $this->formatDataForAi($allData);
}

private function parseOdooResponse($xmlResponse, $label)
{
    try {
        $xml = simplexml_load_string($xmlResponse);

        // Odoo fault responses live under <fault>, not <params>
        if (isset($xml->fault)) {
            $faultString = (string)($xml->fault->value->struct->member[1]->value->string ?? 'Unknown error');
            \Log::error("Odoo fault for $label: $faultString");
            return ['error' => "Odoo error for $label: $faultString"];
        }

        // Navigate to the array of results
        if (isset($xml->params->param->value->array->data->value)) {
            $results = [];
            foreach ($xml->params->param->value->array->data->value as $record) {
                $item = [];
                if (isset($record->struct->member)) {
                    foreach ($record->struct->member as $member) {
                        $key = (string)$member->name;
                        $value = $this->extractValue($member->value);
                        $item[$key] = $value;
                    }
                }
                if (!empty($item)) {
                    $results[] = $item;
                }
            }
            return $results;
        }
        
        return [];
    } catch (\Exception $e) {
        \Log::error('XML Parsing error for ' . $label . ': ' . $e->getMessage());
       // return ['error' => 'Parsing failed: ' . $e->getMessage()];
    }
}

private function extractValue($valueNode)
{
    if (isset($valueNode->string)) {
        return (string)$valueNode->string;
    } elseif (isset($valueNode->int)) {
        return (int)$valueNode->int;
    } elseif (isset($valueNode->double)) {
        return (float)$valueNode->double;
    } elseif (isset($valueNode->boolean)) {
        return (bool)$valueNode->boolean;
    } elseif (isset($valueNode->array)) {
        // Many2one fields come as [id, "name"] — extract the name
        $items = $valueNode->array->data->value;
        $count = count($items);
        if ($count === 2) {
            $second = $this->extractValue($items[1]);
            if (is_string($second) && $second !== '') {
                return $second;
            }
        }
        if ($count === 0) {
            return '';
        }
        return 'Array(' . $count . ' items)';
    } elseif (isset($valueNode->struct)) {
        return 'Object';
    } else {
        return (string)$valueNode;
    }
}

private function formatDataForAi($data)
{
    $formatted = [];

    foreach ($data as $label => $items) {
        if (isset($items['error'])) {
            $formatted[] = "=== $label ===";
            $formatted[] = "Error: " . $items['error'];
            continue;
        }

        if (empty($items)) {
            $formatted[] = "=== $label ===";
            $formatted[] = "No data available";
            continue;
        }

        // Special handling: aggregate Purchase_Order_Lines by product
        if ($label === 'Purchase_Order_Lines') {
            $formatted[] = "=== Top Purchased Products (aggregated from Purchase Order Lines) ===";
            $aggregated = [];
            foreach ($items as $line) {
                $product = $line['product_id'] ?? 'Unknown';
                if (!isset($aggregated[$product])) {
                    $aggregated[$product] = ['qty' => 0, 'received' => 0, 'spend' => 0, 'lines' => 0];
                }
                $aggregated[$product]['qty']      += (float)($line['product_qty'] ?? 0);
                $aggregated[$product]['received'] += (float)($line['qty_received'] ?? 0);
                $aggregated[$product]['spend']    += (float)($line['price_subtotal'] ?? 0);
                $aggregated[$product]['lines']++;
            }
            uasort($aggregated, fn($a, $b) => $b['qty'] <=> $a['qty']);

            $rank = 1;
            foreach ($aggregated as $product => $stats) {
                $formatted[] = sprintf(
                    "%d. %s — Qty Ordered: %.0f | Qty Received: %.0f | Total Spend: Rs. %.2f | Order Lines: %d",
                    $rank++,
                    $product,
                    $stats['qty'],
                    $stats['received'],
                    $stats['spend'],
                    $stats['lines']
                );
            }
            $formatted[] = "";
            continue;
        }

        // Special handling: aggregate Sale_Order_Lines by product
        if ($label === 'Sale_Order_Lines') {
            $formatted[] = "=== Top Selling Products (aggregated from Sale Order Lines) ===";
            $aggregated = [];
            foreach ($items as $line) {
                $product = $line['product_id'] ?? 'Unknown';
                if (!isset($aggregated[$product])) {
                    $aggregated[$product] = ['qty' => 0, 'revenue' => 0, 'orders' => 0];
                }
                $aggregated[$product]['qty']     += (float)($line['product_uom_qty'] ?? 0);
                $aggregated[$product]['revenue'] += (float)($line['price_subtotal'] ?? 0);
                $aggregated[$product]['orders']++;
            }
            // Sort by quantity sold descending
            uasort($aggregated, fn($a, $b) => $b['qty'] <=> $a['qty']);

            $rank = 1;
            foreach ($aggregated as $product => $stats) {
                $formatted[] = sprintf(
                    "%d. %s — Qty Sold: %.0f | Revenue: Rs. %.2f | Order Lines: %d",
                    $rank++,
                    $product,
                    $stats['qty'],
                    $stats['revenue'],
                    $stats['orders']
                );
            }
            $formatted[] = "";
            continue;
        }

        // Special handling: aggregate Invoices by month
        if ($label === 'Invoices') {
            $byMonth = [];
            foreach ($items as $invoice) {
                $dateRaw = $invoice['invoice_date'] ?? '';
                $monthKey = strlen($dateRaw) >= 7 ? substr($dateRaw, 0, 7) : 'Unknown';
                if (!isset($byMonth[$monthKey])) {
                    $byMonth[$monthKey] = ['total' => 0, 'count' => 0, 'invoices' => []];
                }
                $byMonth[$monthKey]['total'] += (float)($invoice['amount_total'] ?? 0);
                $byMonth[$monthKey]['count']++;
                $byMonth[$monthKey]['invoices'][] = ($invoice['name'] ?? '?') . ' | ' . ($invoice['partner_id'] ?? '?') . ' | Rs. ' . number_format((float)($invoice['amount_total'] ?? 0), 2) . ' | ' . ($invoice['payment_state'] ?? '?');
            }
            ksort($byMonth);

            $formatted[] = "=== Invoices by Month ===";
            foreach ($byMonth as $month => $stats) {
                $monthLabel = $month !== 'Unknown' ? date('F Y', strtotime($month . '-01')) : 'Unknown';
                $formatted[] = sprintf(
                    "%s | %d invoices | Total: Rs. %.2f",
                    $monthLabel,
                    $stats['count'],
                    $stats['total']
                );
                foreach ($stats['invoices'] as $inv) {
                    $formatted[] = "    - $inv";
                }
            }
            $formatted[] = "";

            // Also keep flat list for other invoice questions
            $formatted[] = "=== Invoices (full list) ===";
            foreach ($items as $index => $item) {
                $formatted[] = "Record " . ($index + 1) . ":";
                foreach ($item as $key => $value) {
                    $readableKey = str_replace('_', ' ', ucfirst($key));
                    $formatted[] = "  - $readableKey: " . $value;
                }
                $formatted[] = "";
            }
            continue;
        }

        // Special handling: aggregate Sales_Orders by month
        if ($label === 'Sales_Orders') {
            $byMonth = [];
            foreach ($items as $order) {
                $dateRaw = $order['date_order'] ?? '';
                // date_order is "YYYY-MM-DD HH:MM:SS" or "YYYY-MM-DD"
                $monthKey = strlen($dateRaw) >= 7 ? substr($dateRaw, 0, 7) : 'Unknown';
                if (!isset($byMonth[$monthKey])) {
                    $byMonth[$monthKey] = ['total' => 0, 'count' => 0, 'orders' => []];
                }
                $byMonth[$monthKey]['total'] += (float)($order['amount_total'] ?? 0);
                $byMonth[$monthKey]['count']++;
                $byMonth[$monthKey]['orders'][] = ($order['name'] ?? '?') . ' (Rs. ' . number_format((float)($order['amount_total'] ?? 0), 2) . ')';
            }
            ksort($byMonth);

            $formatted[] = "=== Sales Orders by Month ===";
            foreach ($byMonth as $month => $stats) {
                $monthLabel = $month !== 'Unknown' ? date('F Y', strtotime($month . '-01')) : 'Unknown';
                $formatted[] = sprintf(
                    "%s | %d orders | Total: Rs. %.2f",
                    $monthLabel,
                    $stats['count'],
                    $stats['total']
                );
                foreach ($stats['orders'] as $o) {
                    $formatted[] = "    - $o";
                }
            }
            $formatted[] = "";

            // Also add the flat list so the AI can answer other sales questions
            $formatted[] = "=== Sales_Orders (full list) ===";
            foreach ($items as $index => $item) {
                $formatted[] = "Record " . ($index + 1) . ":";
                foreach ($item as $key => $value) {
                    $readableKey = str_replace('_', ' ', ucfirst($key));
                    $formatted[] = "  - $readableKey: " . $value;
                }
                $formatted[] = "";
            }
            continue;
        }

        $formatted[] = "=== $label ===";

        // Format each record (cap at 50 records to avoid context overflow)
        $items = array_slice($items, 0, 50);
        foreach ($items as $index => $item) {
            $formatted[] = "Record " . ($index + 1) . ":";
            foreach ($item as $key => $value) {
                $readableKey = str_replace('_', ' ', ucfirst($key));
                $formatted[] = "  - $readableKey: " . $value;
            }
            $formatted[] = "";
        }
    }

    return implode("\n", $formatted);
}
    private function getAiResponse($userMessage, $odooContext)
{
    // API link
    $apiKey = config('services.openrouter.api_key');
    $model = config('services.openrouter.model');

    //check api key
    if (!$apiKey) {
        throw new Exception('OpenRouter API Key not configured');
    }

    //prompt - Improved with better instructions
    $prompt = "You are a helpful Odoo Business Assistant.

    Here is the current business data from Odoo:

    $odooContext

    User's question: '$userMessage'

    CRITICAL RULES — follow these exactly:
    1. All monetary values are in Sri Lankan Rupees (LKR). Always display amounts with the prefix Rs. — NEVER use dollar sign or USD.
    2. SALES data (selling to customers): use ONLY the sections named Sales_Orders and Top Selling Products.
    3. PURCHASE data (buying from vendors): use ONLY the sections named Purchase_Orders and Top Purchased Products.
    4. NEVER mix these two. If the user asks about purchases or most purchased products, show Top Purchased Products — NOT Top Selling Products.
    5. Standard price = cost price. List price = selling price.
    6. Present rankings as numbered lists with all available stats (qty, revenue/spend, order lines).
    7. If you cannot find specific information, politely say so and suggest what information is available.
    8. Use the data above — it is real, live data already formatted for you.
    9. When the user asks for sales by month or monthly sales, use the Sales Orders by Month section - list EVERY month that appears in that section with its order count and total. Do NOT mention or invent months that are not in the data.
    10. When the user asks for invoices by month or invoice summary by month, use the Invoices by Month section - list EVERY month that appears in that section with its invoice count and total. Do NOT mention or invent months that are not in the data.
    11. NEVER say a month has no data or is unavailable. Simply skip months that do not appear in the data sections.

    Please respond helpfully:";

    $response = Http::withHeaders([
        'Authorization' => 'Bearer ' . $apiKey,
        'Content-Type' => 'application/json',
        'HTTP-Referer' => config('app.url'),
        'X-Title' => config('app.name'),
    ])->post('https://openrouter.ai/api/v1/chat/completions', [
        'model' => $model,
        'messages' => [
            ['role' => 'system', 'content' => 'You are an Odoo business assistant with access to real business data. IMPORTANT: Sales data (Top Selling Products) is about selling to customers. Purchase data (Top Purchased Products) is about buying from vendors. Never confuse the two. All monetary values are in Sri Lankan Rupees — always use "Rs." prefix, never "$" or "USD". Answer naturally and helpfully in English.'],
            ['role' => 'user', 'content' => $prompt]
        ],
        'temperature' => 0.7,
    ]);

    if ($response->failed()) {
        throw new Exception('OpenRouter API Error: ' . $response->body());
    }

    $result = $response->json();
    return $result['choices'][0]['message']['content'] ?? 'Sorry, I could not retrieve an answer.';
}

}
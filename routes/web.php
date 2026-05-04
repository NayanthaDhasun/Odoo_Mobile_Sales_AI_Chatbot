<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\OdooController;



/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/


// Chatbot layout
Route::get('/chat', [OdooController::class, 'index'])->name('chat');

//main-page 
Route::get('/', [OdooController::class, 'mainPage'])->name('main-page');

// Chat messages handler
Route::post('/odoo/chat', [OdooController::class, 'chat']);


// endpoints
Route::get('/odoo/products/{productName}', [OdooController::class, 'getProductDetails']);
Route::get('/odoo/total-sales', [OdooController::class, 'getTotalSales']);
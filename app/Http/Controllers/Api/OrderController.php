<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use App\Events\OrderPlaced;

class OrderController extends Controller
{
    public function __construct()
    {
        $this->middleware("auth:sanctum");
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return auth()->user()->orders()->with("items.product")->latest()->paginate(10);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            "items" => "required|array",
            "items.*.product_id" => "required|exists:products,id",
            "items.*.quantity" => "required|integer|min:1",
        ]);

        // Calculate order total and check stock availability
        $total = 0;
        $items = [];

        foreach ($validated["items"] as $item) {
            $product = Product::findOrFail($item["product_id"]);

            // Check if product is in stock
            if ($product->stock < $item["quantity"]) {
                return response()->json([
                    "message" => "Product {$product->name} is out of stock. Only {$product->stock} available.",
                ], 422);
            }

            $itemTotal = $product->price * $item["quantity"];
            $total += $itemTotal;

            $items[] = [
                "product_id" => $product->id,
                "quantity" => $item["quantity"],
                "price" => $product->price,
            ];

            // Decrease stock
            $product->update([
                "stock" => $product->stock - $item["quantity"]
            ]);
        }

        // Create order
        $order = Order::create([
            "user_id" => auth()->id(),
            "total" => $total,
            "status" => "pending",
        ]);

        // Add order items
        foreach ($items as $item) {
            $order->items()->create($item);
        }

        // Trigger order placed event
        event(new OrderPlaced($order));

        return response()->json([
            "message" => "Order placed successfully",
            "order" => $order->load("items.product"),
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Order $order)
    {
        // Check if order belongs to authenticated user
        if ($order->user_id !== auth()->id()) {
            return response()->json([
                "message" => "Unauthorized",
            ], 403);
        }

        return $order->load("items.product");
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}

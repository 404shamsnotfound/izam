<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Models\Product;
use App\Repositories\Interfaces\OrderRepositoryInterface;
use App\Repositories\Interfaces\ProductRepositoryInterface;
use Illuminate\Http\Request;
use App\Events\OrderPlaced;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class OrderController extends Controller
{
    /**
     * @var OrderRepositoryInterface
     */
    private OrderRepositoryInterface $orderRepository;
    
    /**
     * @var ProductRepositoryInterface
     */
    private ProductRepositoryInterface $productRepository;
    
    /**
     * OrderController constructor.
     * 
     * @param OrderRepositoryInterface $orderRepository
     * @param ProductRepositoryInterface $productRepository
     */
    public function __construct(
        OrderRepositoryInterface $orderRepository,
        ProductRepositoryInterface $productRepository
    ) {
        $this->middleware("auth:sanctum");
        $this->orderRepository = $orderRepository;
        $this->productRepository = $productRepository;
    }

    /**
     * Display a listing of the resource.
     * 
     * @return AnonymousResourceCollection
     */
    public function index(): AnonymousResourceCollection
    {
        $userId = auth()->id();
        $orders = $this->orderRepository->getByUser($userId, 10);
        
        return OrderResource::collection($orders);
    }

    /**
     * Store a newly created resource in storage.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
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
            $product = $this->productRepository->find($item["product_id"]);

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
            $this->productRepository->updateStock($product->id, $item["quantity"]);
        }

        // Create order
        $orderData = [
            "user_id" => auth()->id(),
            "total" => $total,
            "status" => "pending",
        ];
        
        $order = $this->orderRepository->createWithItems($orderData, $items);

        // Trigger order placed event
        event(new OrderPlaced($order));

        return response()->json([
            "message" => "Order placed successfully",
            "order" => new OrderResource($order),
        ], 201);
    }

    /**
     * Display the specified resource.
     * 
     * @param int $id
     * @return OrderResource|\Illuminate\Http\JsonResponse
     */
    public function show(int $id)
    {
        $order = $this->orderRepository->findWithRelations($id, ['items.product']);
        
        // Check if order belongs to authenticated user
        if ($order->user_id !== auth()->id()) {
            return response()->json([
                "message" => "Unauthorized",
            ], 403);
        }

        return new OrderResource($order);
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

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ProductController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Product::query();

        // Filter by name
        if ($request->has("name")) {
            $query->where("name", "like", "%" . $request->name . "%");
        }

        // Filter by price range
        if ($request->has("min_price")) {
            $query->where("price", ">=", $request->min_price);
        }

        if ($request->has("max_price")) {
            $query->where("price", "<=", $request->max_price);
        }

        // Filter by category
        if ($request->has("category")) {
            $query->where("category", $request->category);
        }

        // Cache results to improve performance
        $cacheKey = "products_" . md5(json_encode($request->all()));
        $perPage = $request->input("per_page", 10);

        return Cache::remember($cacheKey, 600, function () use ($query, $perPage) {
            return $query->paginate($perPage);
        });
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            "name" => "required|string|max:255",
            "description" => "required|string",
            "price" => "required|numeric|min:0",
            "category" => "required|string|max:100",
            "stock" => "required|integer|min:0",
            "image" => "nullable|string",
        ]);

        return Product::create($validated);
    }

    /**
     * Display the specified resource.
     */
    public function show(Product $product)
    {
        return $product;
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Product $product)
    {
        $validated = $request->validate([
            "name" => "sometimes|string|max:255",
            "description" => "sometimes|string",
            "price" => "sometimes|numeric|min:0",
            "category" => "sometimes|string|max:100",
            "stock" => "sometimes|integer|min:0",
            "image" => "nullable|string",
        ]);

        $product->update($validated);
        return $product;
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Product $product)
    {
        $product->delete();
        return response()->json(null, 204);
    }
}

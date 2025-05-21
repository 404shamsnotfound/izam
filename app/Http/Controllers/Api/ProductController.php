<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use App\Repositories\Interfaces\ProductRepositoryInterface;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProductController extends Controller
{
    /**
     * @var ProductRepositoryInterface
     */
    private ProductRepositoryInterface $productRepository;

    /**
     * ProductController constructor.
     * 
     * @param ProductRepositoryInterface $productRepository
     */
    public function __construct(ProductRepositoryInterface $productRepository)
    {
        $this->productRepository = $productRepository;
    }

    /**
     * Display a listing of the resource.
     * 
     * @param Request $request
     * @return AnonymousResourceCollection
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->only([
            'name',
            'min_price',
            'max_price',
            'category',
        ]);

        $perPage = $request->input('per_page', 10);
        $products = $this->productRepository->filter($filters, $perPage);

        return ProductResource::collection($products);
    }

    /**
     * Store a newly created resource in storage.
     * 
     * @param Request $request
     * @return ProductResource
     */
    public function store(Request $request): ProductResource
    {
        $validated = $request->validate([
            "name" => "required|string|max:255",
            "description" => "required|string",
            "price" => "required|numeric|min:0",
            "category" => "required|string|max:100",
            "stock" => "required|integer|min:0",
            "image" => "nullable|string",
        ]);

        $product = $this->productRepository->create($validated);
        
        return new ProductResource($product);
    }

    /**
     * Display the specified resource.
     * 
     * @param int $id
     * @return ProductResource
     */
    public function show(int $id): ProductResource
    {
        $product = $this->productRepository->find($id);
        
        return new ProductResource($product);
    }

    /**
     * Update the specified resource in storage.
     * 
     * @param Request $request
     * @param int $id
     * @return ProductResource
     */
    public function update(Request $request, int $id): ProductResource
    {
        $validated = $request->validate([
            "name" => "sometimes|string|max:255",
            "description" => "sometimes|string",
            "price" => "sometimes|numeric|min:0",
            "category" => "sometimes|string|max:100",
            "stock" => "sometimes|integer|min:0",
            "image" => "nullable|string",
        ]);

        $product = $this->productRepository->update($validated, $id);
        
        return new ProductResource($product);
    }

    /**
     * Remove the specified resource from storage.
     * 
     * @param int $id
     * @return \Illuminate\Http\Response
     */
    public function destroy(int $id)
    {
        $this->productRepository->delete($id);
        
        return response()->json(null, 204);
    }
}

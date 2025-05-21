<?php

namespace App\Repositories\Eloquent;

use App\Models\Product;
use App\Repositories\Interfaces\ProductRepositoryInterface;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Cache;

class ProductRepository extends BaseRepository implements ProductRepositoryInterface
{
    /**
     * ProductRepository constructor.
     * 
     * @param Product $model
     */
    public function __construct(Product $model)
    {
        parent::__construct($model);
    }

    /**
     * @inheritdoc
     */
    public function filter(array $filters, int $perPage = 10): LengthAwarePaginator
    {
        $query = $this->model->query();

        // Apply filters
        if (isset($filters['name'])) {
            $query->where('name', 'like', '%' . $filters['name'] . '%');
        }

        if (isset($filters['min_price'])) {
            $query->where('price', '>=', $filters['min_price']);
        }

        if (isset($filters['max_price'])) {
            $query->where('price', '<=', $filters['max_price']);
        }

        if (isset($filters['category'])) {
            $query->where('category', $filters['category']);
        }

        // Cache results to improve performance
        $cacheKey = 'products_' . md5(json_encode($filters));
        
        return Cache::remember($cacheKey, 600, function () use ($query, $perPage) {
            return $query->paginate($perPage);
        });
    }

    /**
     * @inheritdoc
     */
    public function find(int $id, array $columns = ['*']): ?Product
    {
        return $this->model->find($id, $columns);
    }

    /**
     * @inheritdoc
     */
    public function updateStock(int $id, int $quantity): Product
    {
        $product = $this->find($id);
        $product->update([
            'stock' => $product->stock - $quantity
        ]);
        return $product;
    }
} 
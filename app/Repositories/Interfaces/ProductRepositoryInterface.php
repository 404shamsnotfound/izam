<?php

namespace App\Repositories\Interfaces;

use App\Models\Product;
use Illuminate\Pagination\LengthAwarePaginator;

interface ProductRepositoryInterface extends RepositoryInterface
{
    /**
     * Filter products by criteria
     *
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function filter(array $filters, int $perPage = 10): LengthAwarePaginator;
    
    /**
     * Find product by ID
     *
     * @param int $id
     * @return Product|null
     */
    public function find(int $id, array $columns = ['*']): ?Product;
    
    /**
     * Update product stock
     *
     * @param int $id
     * @param int $quantity
     * @return Product
     */
    public function updateStock(int $id, int $quantity): Product;
} 
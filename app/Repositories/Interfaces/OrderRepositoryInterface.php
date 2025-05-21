<?php

namespace App\Repositories\Interfaces;

use App\Models\Order;
use Illuminate\Pagination\LengthAwarePaginator;

interface OrderRepositoryInterface extends RepositoryInterface
{
    /**
     * Get orders for a specific user
     *
     * @param int $userId
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getByUser(int $userId, int $perPage = 10): LengthAwarePaginator;
    
    /**
     * Create order with items
     *
     * @param array $orderData
     * @param array $items
     * @return Order
     */
    public function createWithItems(array $orderData, array $items): Order;
    
    /**
     * Find order by ID with relations
     *
     * @param int $id
     * @param array $relations
     * @return Order|null
     */
    public function findWithRelations(int $id, array $relations = []): ?Order;
} 
<?php

namespace App\Repositories\Eloquent;

use App\Models\Order;
use App\Repositories\Interfaces\OrderRepositoryInterface;
use Illuminate\Pagination\LengthAwarePaginator;

class OrderRepository extends BaseRepository implements OrderRepositoryInterface
{
    /**
     * OrderRepository constructor.
     * 
     * @param Order $model
     */
    public function __construct(Order $model)
    {
        parent::__construct($model);
    }

    /**
     * @inheritdoc
     */
    public function getByUser(int $userId, int $perPage = 10): LengthAwarePaginator
    {
        return $this->model
            ->where('user_id', $userId)
            ->with('items.product')
            ->latest()
            ->paginate($perPage);
    }

    /**
     * @inheritdoc
     */
    public function createWithItems(array $orderData, array $items): Order
    {
        $order = $this->create($orderData);
        
        // Add order items
        foreach ($items as $item) {
            $order->items()->create($item);
        }
        
        return $order->load('items.product');
    }

    /**
     * @inheritdoc
     */
    public function findWithRelations(int $id, array $relations = []): ?Order
    {
        return $this->model->with($relations)->find($id);
    }
} 
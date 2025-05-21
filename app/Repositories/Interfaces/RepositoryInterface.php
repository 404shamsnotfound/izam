<?php

namespace App\Repositories\Interfaces;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Pagination\LengthAwarePaginator;

interface RepositoryInterface
{
    /**
     * Get all resources
     * 
     * @param array $columns
     * @return Collection
     */
    public function all(array $columns = ['*']): Collection;
    
    /**
     * Get paginated resources
     * 
     * @param int $perPage
     * @param array $columns
     * @return LengthAwarePaginator
     */
    public function paginate(int $perPage = 10, array $columns = ['*']): LengthAwarePaginator;
    
    /**
     * Create new resource
     * 
     * @param array $data
     * @return Model
     */
    public function create(array $data): Model;
    
    /**
     * Update existing resource
     * 
     * @param array $data
     * @param int $id
     * @return Model
     */
    public function update(array $data, int $id): Model;
    
    /**
     * Delete resource
     * 
     * @param int $id
     * @return bool
     */
    public function delete(int $id): bool;
    
    /**
     * Find resource by id
     * 
     * @param int $id
     * @param array $columns
     * @return Model|null
     */
    public function find(int $id, array $columns = ['*']): ?Model;
    
    /**
     * Find resource by field value
     * 
     * @param string $field
     * @param mixed $value
     * @param array $columns
     * @return Model|null
     */
    public function findBy(string $field, mixed $value, array $columns = ['*']): ?Model;
} 
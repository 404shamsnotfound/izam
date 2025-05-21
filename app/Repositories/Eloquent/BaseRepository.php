<?php

namespace App\Repositories\Eloquent;

use App\Repositories\Interfaces\RepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Pagination\LengthAwarePaginator;

abstract class BaseRepository implements RepositoryInterface
{
    /**
     * @var Model
     */
    protected Model $model;

    /**
     * BaseRepository constructor.
     * 
     * @param Model $model
     */
    public function __construct(Model $model)
    {
        $this->model = $model;
    }

    /**
     * @inheritdoc
     */
    public function all(array $columns = ['*']): Collection
    {
        return $this->model->all($columns);
    }

    /**
     * @inheritdoc
     */
    public function paginate(int $perPage = 10, array $columns = ['*']): LengthAwarePaginator
    {
        // Explicitly set the page from request
        $page = request()->input('page', 1);
        return $this->model->paginate($perPage, $columns, 'page', $page);
    }

    /**
     * @inheritdoc
     */
    public function create(array $data): Model
    {
        return $this->model->create($data);
    }

    /**
     * @inheritdoc
     */
    public function update(array $data, int $id): Model
    {
        $record = $this->find($id);
        $record->update($data);
        return $record;
    }

    /**
     * @inheritdoc
     */
    public function delete(int $id): bool
    {
        return $this->find($id)->delete();
    }

    /**
     * @inheritdoc
     */
    public function find(int $id, array $columns = ['*']): ?Model
    {
        return $this->model->find($id, $columns);
    }

    /**
     * @inheritdoc
     */
    public function findBy(string $field, mixed $value, array $columns = ['*']): ?Model
    {
        return $this->model->where($field, $value)->first($columns);
    }
} 
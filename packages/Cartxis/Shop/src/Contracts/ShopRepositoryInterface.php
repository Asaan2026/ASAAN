<?php

namespace Cartxis\Shop\Contracts;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

interface ShopRepositoryInterface
{
    /**
     * Get all records.
     *
     * @param  array  $columns
     * @return Collection
     */
    public function all($columns = ['*']);

    /**
     * Find a record by id.
     *
     * @param  int  $id
     * @param  array  $columns
     * @return Model|null
     */
    public function find($id, $columns = ['*']);

    /**
     * Find a record by field and value.
     *
     * @param  string  $field
     * @param  mixed  $value
     * @param  array  $columns
     * @return Model|null
     */
    public function findByField($field, $value, $columns = ['*']);

    /**
     * Find records where field value is in given array.
     *
     * @param  string  $field
     * @param  array  $columns
     * @return Collection
     */
    public function findWhereIn($field, array $values, $columns = ['*']);

    /**
     * Create a new record.
     *
     * @return Model
     */
    public function create(array $data);

    /**
     * Update a record.
     *
     * @param  int  $id
     * @return Model
     */
    public function update(array $data, $id);

    /**
     * Delete a record.
     *
     * @param  int  $id
     * @return bool
     */
    public function delete($id);

    /**
     * Get paginated records.
     *
     * @param  int  $perPage
     * @param  array  $columns
     * @return LengthAwarePaginator
     */
    public function paginate($perPage = 15, $columns = ['*']);
}

<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Product>
 */
class ProductFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $categories = ["Electronics", "Clothing", "Books", "Home", "Toys"];
        
        return [
            "name" => $this->faker->words(3, true),
            "description" => $this->faker->paragraph(),
            "price" => $this->faker->randomFloat(2, 10, 1000),
            "category" => $this->faker->randomElement($categories),
            "stock" => $this->faker->numberBetween(0, 100),
            "image" => "https://picsum.photos/id/" . $this->faker->numberBetween(1, 1000) . "/300/300",
        ];
    }
}

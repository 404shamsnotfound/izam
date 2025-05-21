#!/bin/bash

# Implement Product model
docker-compose exec app bash -c 'cat > app/Models/Product.php << "EOF"
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        "name",
        "description",
        "price",
        "category",
        "stock",
        "image",
    ];

    public function orders()
    {
        return $this->belongsToMany(Order::class, "order_items")
            ->withPivot("quantity", "price")
            ->withTimestamps();
    }
}
EOF'

# Implement Order model
docker-compose exec app bash -c 'cat > app/Models/Order.php << "EOF"
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        "user_id",
        "total",
        "status",
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function products()
    {
        return $this->belongsToMany(Product::class, "order_items")
            ->withPivot("quantity", "price")
            ->withTimestamps();
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
EOF'

# Implement OrderItem model
docker-compose exec app bash -c 'cat > app/Models/OrderItem.php << "EOF"
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        "order_id",
        "product_id",
        "quantity",
        "price",
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
EOF'

# Implement migrations
docker-compose exec app bash -c 'cat > database/migrations/2023_01_01_000001_create_products_table.php << "EOF"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create("products", function (Blueprint $table) {
            $table->id();
            $table->string("name");
            $table->text("description");
            $table->decimal("price", 10, 2);
            $table->string("category");
            $table->integer("stock")->default(0);
            $table->string("image")->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists("products");
    }
};
EOF'

docker-compose exec app bash -c 'cat > database/migrations/2023_01_01_000002_create_orders_table.php << "EOF"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create("orders", function (Blueprint $table) {
            $table->id();
            $table->foreignId("user_id")->constrained()->onDelete("cascade");
            $table->decimal("total", 10, 2);
            $table->string("status")->default("pending");
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists("orders");
    }
};
EOF'

docker-compose exec app bash -c 'cat > database/migrations/2023_01_01_000003_create_order_items_table.php << "EOF"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create("order_items", function (Blueprint $table) {
            $table->id();
            $table->foreignId("order_id")->constrained()->onDelete("cascade");
            $table->foreignId("product_id")->constrained()->onDelete("cascade");
            $table->integer("quantity");
            $table->decimal("price", 10, 2);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists("order_items");
    }
};
EOF'

# Implement controllers
docker-compose exec app bash -c 'cat > app/Http/Controllers/Api/ProductController.php << "EOF"
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ProductController extends Controller
{
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

    public function show(Product $product)
    {
        return $product;
    }

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

    public function destroy(Product $product)
    {
        $product->delete();
        return response()->json(null, 204);
    }
}
EOF'

docker-compose exec app bash -c 'cat > app/Http/Controllers/Api/OrderController.php << "EOF"
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use App\Events\OrderPlaced;

class OrderController extends Controller
{
    public function __construct()
    {
        $this->middleware("auth:sanctum");
    }

    public function index()
    {
        return auth()->user()->orders()->with("items.product")->latest()->paginate(10);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            "items" => "required|array",
            "items.*.product_id" => "required|exists:products,id",
            "items.*.quantity" => "required|integer|min:1",
        ]);

        // Calculate order total and check stock availability
        $total = 0;
        $items = [];

        foreach ($validated["items"] as $item) {
            $product = Product::findOrFail($item["product_id"]);

            // Check if product is in stock
            if ($product->stock < $item["quantity"]) {
                return response()->json([
                    "message" => "Product {$product->name} is out of stock. Only {$product->stock} available.",
                ], 422);
            }

            $itemTotal = $product->price * $item["quantity"];
            $total += $itemTotal;

            $items[] = [
                "product_id" => $product->id,
                "quantity" => $item["quantity"],
                "price" => $product->price,
            ];

            // Decrease stock
            $product->update([
                "stock" => $product->stock - $item["quantity"]
            ]);
        }

        // Create order
        $order = Order::create([
            "user_id" => auth()->id(),
            "total" => $total,
            "status" => "pending",
        ]);

        // Add order items
        foreach ($items as $item) {
            $order->items()->create($item);
        }

        // Trigger order placed event
        event(new OrderPlaced($order));

        return response()->json([
            "message" => "Order placed successfully",
            "order" => $order->load("items.product"),
        ], 201);
    }

    public function show(Order $order)
    {
        // Check if order belongs to authenticated user
        if ($order->user_id !== auth()->id()) {
            return response()->json([
                "message" => "Unauthorized",
            ], 403);
        }

        return $order->load("items.product");
    }
}
EOF'

docker-compose exec app bash -c 'cat > app/Http/Controllers/Api/AuthController.php << "EOF"
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            "name" => "required|string|max:255",
            "email" => "required|string|email|max:255|unique:users",
            "password" => "required|string|min:8|confirmed",
        ]);

        $user = User::create([
            "name" => $request->name,
            "email" => $request->email,
            "password" => Hash::make($request->password),
        ]);

        $token = $user->createToken("auth_token")->plainTextToken;

        return response()->json([
            "user" => $user,
            "token" => $token,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            "email" => "required|string|email",
            "password" => "required|string",
        ]);

        $user = User::where("email", $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                "email" => ["The provided credentials are incorrect."],
            ]);
        }

        $token = $user->createToken("auth_token")->plainTextToken;

        return response()->json([
            "user" => $user,
            "token" => $token,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            "message" => "Logged out successfully",
        ]);
    }

    public function user(Request $request)
    {
        return $request->user();
    }
}
EOF'

# Implement events and listeners
docker-compose exec app bash -c 'cat > app/Events/OrderPlaced.php << "EOF"
<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderPlaced
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $order;

    public function __construct(Order $order)
    {
        $this->order = $order;
    }
}
EOF'

docker-compose exec app bash -c 'cat > app/Listeners/SendOrderNotification.php << "EOF"
<?php

namespace App\Listeners;

use App\Events\OrderPlaced;
use Illuminate\Support\Facades\Log;

class SendOrderNotification
{
    public function __construct()
    {
        //
    }

    public function handle(OrderPlaced $event)
    {
        // In a real application, we would send an email to the admin
        // For this test task, we just log the event
        Log::info("Order placed", [
            "order_id" => $event->order->id,
            "user_id" => $event->order->user_id,
            "total" => $event->order->total,
        ]);
    }
}
EOF'

# Update event service provider
docker-compose exec app bash -c 'cat > app/Providers/EventServiceProvider.php << "EOF"
<?php

namespace App\Providers;

use App\Events\OrderPlaced;
use App\Listeners\SendOrderNotification;
use Illuminate\Auth\Events\Registered;
use Illuminate\Auth\Listeners\SendEmailVerificationNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        Registered::class => [
            SendEmailVerificationNotification::class,
        ],
        OrderPlaced::class => [
            SendOrderNotification::class,
        ],
    ];

    public function boot()
    {
        //
    }

    public function shouldDiscoverEvents()
    {
        return false;
    }
}
EOF'

# Set up routes
docker-compose exec app bash -c 'cat > routes/api.php << "EOF"
<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post("/register", [AuthController::class, "register"]);
Route::post("/login", [AuthController::class, "login"]);
Route::get("/products", [ProductController::class, "index"]);
Route::get("/products/{product}", [ProductController::class, "show"]);

// Protected routes
Route::middleware("auth:sanctum")->group(function () {
    Route::post("/logout", [AuthController::class, "logout"]);
    Route::get("/user", [AuthController::class, "user"]);
    
    Route::get("/orders", [OrderController::class, "index"]);
    Route::post("/orders", [OrderController::class, "store"]);
    Route::get("/orders/{order}", [OrderController::class, "show"]);
});
EOF'

# Implement product factory and seeder
docker-compose exec app bash -c 'cat > database/factories/ProductFactory.php << "EOF"
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class ProductFactory extends Factory
{
    public function definition()
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
EOF'

docker-compose exec app bash -c 'cat > database/seeders/ProductSeeder.php << "EOF"
<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run()
    {
        Product::factory()->count(50)->create();
    }
}
EOF'

docker-compose exec app bash -c 'cat > database/seeders/DatabaseSeeder.php << "EOF"
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        $this->call([
            ProductSeeder::class,
        ]);
    }
}
EOF'

# Run migrations and seeders
docker-compose exec app php artisan migrate:fresh --seed

echo "Backend implementation completed!" 
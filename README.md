# Laravel React E-commerce Project

This is a full-stack e-commerce application built with Laravel (backend) and React with TypeScript (frontend).

## Requirements

- Docker & Docker Compose

## Setup Instructions

1. Clone this repository
2. Start the Docker containers:
   ```
   docker-compose up -d
   ```
3. Install backend dependencies:
   ```
   docker exec -it izam-app composer install
   docker exec -it izam-app php artisan key:generate
   docker exec -it izam-app php artisan migrate --seed
   ```
4. Install frontend dependencies and build:
   ```
   docker exec -it izam-app npm install
   docker exec -it izam-app npm run build
   ```
5. The application will be available at http://localhost:8000

## Running the Application

### Backend Only
To run only the backend API:
```
docker-compose up -d db redis app nginx
```

### Frontend Development
To run the frontend in development mode with hot reload:
```
docker exec -it izam-app npm run dev
```

### Production Build
To build the frontend for production:
```
docker exec -it izam-app npm run build
```

## API Documentation

### Authentication Endpoints

#### Register a New User
- **URL**: `/api/register`
- **Method**: `POST`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
  ```
- **Response**: 
  ```json
  {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    "token": "1|a1b2c3d4e5f6g7h8i9j0..."
  }
  ```

#### Login
- **URL**: `/api/login`
- **Method**: `POST`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "email": "john@example.com",
    "password": "password123"
  }
  ```
- **Response**: 
  ```json
  {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    "token": "1|a1b2c3d4e5f6g7h8i9j0..."
  }
  ```

#### Logout
- **URL**: `/api/logout`
- **Method**: `POST`
- **Auth Required**: Yes
- **Headers**: 
  ```
  Authorization: Bearer {token}
  ```
- **Response**: 
  ```json
  {
    "message": "Logged out successfully"
  }
  ```

#### Get Current User
- **URL**: `/api/user`
- **Method**: `GET`
- **Auth Required**: Yes
- **Headers**: 
  ```
  Authorization: Bearer {token}
  ```
- **Response**: User object

### Product Endpoints

#### List Products
- **URL**: `/api/products`
- **Method**: `GET`
- **Auth Required**: No
- **Query Parameters**:
  - `name`: Filter by product name
  - `min_price`: Filter by minimum price
  - `max_price`: Filter by maximum price
  - `category`: Filter by category
  - `page`: Pagination page number
  - `per_page`: Items per page (default: 10)
- **Response**: Paginated products list

#### Get Product Details
- **URL**: `/api/products/{id}`
- **Method**: `GET`
- **Auth Required**: No
- **Response**: Product object

### Order Endpoints (All Authenticated)

#### List User Orders
- **URL**: `/api/orders`
- **Method**: `GET`
- **Auth Required**: Yes
- **Headers**: 
  ```
  Authorization: Bearer {token}
  ```
- **Response**: Paginated list of user's orders

#### Create Order
- **URL**: `/api/orders`
- **Method**: `POST`
- **Auth Required**: Yes
- **Headers**: 
  ```
  Authorization: Bearer {token}
  ```
- **Request Body**:
  ```json
  {
    "items": [
      {
        "product_id": 1,
        "quantity": 2
      },
      {
        "product_id": 3,
        "quantity": 1
      }
    ]
  }
  ```
- **Response**: 
  ```json
  {
    "message": "Order placed successfully",
    "order": {
      "id": 1,
      "user_id": 1,
      "total": 59.98,
      "status": "pending",
      "items": [...]
    }
  }
  ```

#### Get Order Details
- **URL**: `/api/orders/{id}`
- **Method**: `GET`
- **Auth Required**: Yes
- **Headers**: 
  ```
  Authorization: Bearer {token}
  ```
- **Response**: Order object with related items and products

## Authentication Flow

The application uses Laravel Sanctum for authentication. Here's the flow:

1. **Registration/Login**:
   - User submits credentials
   - Server validates credentials
   - On success, server generates a Sanctum token
   - Token is returned to the client

2. **Token Storage**:
   - Frontend stores the token in localStorage
   - Token is attached to every authenticated request

3. **Request Authentication**:
   - Frontend sends API requests with the Authorization header:
     ```
     Authorization: Bearer {token}
     ```
   - Laravel Sanctum validates the token
   - If valid, the request is processed
   - If invalid, a 401 Unauthorized response is returned

4. **Logout**:
   - User initiates logout
   - Frontend sends logout request with the token
   - Server invalidates the token
   - Frontend removes the token from localStorage

5. **Protected Routes**:
   - Frontend uses React Router with a ProtectedRoute component
   - ProtectedRoute checks for token presence
   - If no token exists, user is redirected to login

## Project Structure

### Backend (Laravel)
- **Models**: 
  - User: Authentication and user management
  - Product: Product information and inventory
  - Order: Customer orders with total and status
  - OrderItem: Individual items within orders

- **Controllers**:
  - AuthController: User authentication
  - ProductController: Product listing and details
  - OrderController: Order creation and management

- **Events & Listeners**:
  - OrderPlaced: Triggered when a new order is created
  - SendOrderNotification: Listener that handles order notifications

### Frontend (React with TypeScript)
- **Contexts**:
  - AuthContext: Authentication state management with type safety
  - CartContext: Shopping cart state management with type safety

- **Pages**:
  - LoginPage: User login
  - RegisterPage: User registration
  - ProductsPage: Product browsing and filtering
  - OrderDetailsPage: Order details view

- **Components**:
  - ProtectedRoute: Route wrapper for authenticated pages

- **Types**:
  - Strong typing for API responses
  - Interface definitions for component props
  - Type definitions for state management

## Technology Stack

- Laravel 10
- React 18 with TypeScript
- Vite with TypeScript configuration
- MySQL 8.0
- Redis
- Docker
- Laravel Sanctum (Authentication)
- Material UI 5
- React Router 6 
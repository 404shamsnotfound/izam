#!/bin/bash

# Create main React file
docker-compose exec app bash -c 'cat > resources/js/app.js << "EOF"
import "./bootstrap";
import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";

// Create root element
const container = document.getElementById("app");
const root = createRoot(container);

// Render the app
root.render(
    <BrowserRouter>
        <App />
    </BrowserRouter>
);
EOF'

# Create App.js with routing
docker-compose exec app bash -c 'cat > resources/js/App.js << "EOF"
import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import { CssBaseline, ThemeProvider, createTheme } from "@mui/material";
import { AuthProvider } from "./contexts/AuthContext";
import { CartProvider } from "./contexts/CartContext";
import ProtectedRoute from "./components/ProtectedRoute";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import ProductsPage from "./pages/ProductsPage";
import OrderDetailsPage from "./pages/OrderDetailsPage";

// Create a theme
const theme = createTheme({
    palette: {
        primary: {
            main: "#1976d2",
        },
        secondary: {
            main: "#dc004e",
        },
    },
});

export default function App() {
    return (
        <ThemeProvider theme={theme}>
            <CssBaseline />
            <AuthProvider>
                <CartProvider>
                    <Routes>
                        <Route path="/login" element={<LoginPage />} />
                        <Route path="/register" element={<RegisterPage />} />
                        <Route
                            path="/products"
                            element={
                                <ProtectedRoute>
                                    <ProductsPage />
                                </ProtectedRoute>
                            }
                        />
                        <Route
                            path="/orders/:id"
                            element={
                                <ProtectedRoute>
                                    <OrderDetailsPage />
                                </ProtectedRoute>
                            }
                        />
                        <Route
                            path="/"
                            element={<Navigate to="/products" replace />}
                        />
                    </Routes>
                </CartProvider>
            </AuthProvider>
        </ThemeProvider>
    );
}
EOF'

# Create auth context
docker-compose exec app bash -c 'cat > resources/js/contexts/AuthContext.js << "EOF"
import React, { createContext, useState, useEffect } from "react";
import axios from "axios";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(localStorage.getItem("token"));
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (token) {
            axios.defaults.headers.common["Authorization"] = `Bearer ${token}`;
            fetchUser();
        } else {
            setLoading(false);
        }
    }, [token]);

    const fetchUser = async () => {
        try {
            const response = await axios.get("/api/user");
            setUser(response.data);
        } catch (error) {
            logout();
        } finally {
            setLoading(false);
        }
    };

    const login = async (email, password) => {
        try {
            const response = await axios.post("/api/login", {
                email,
                password,
            });
            
            setUser(response.data.user);
            setToken(response.data.token);
            localStorage.setItem("token", response.data.token);
            axios.defaults.headers.common["Authorization"] = `Bearer ${response.data.token}`;
            
            return response.data;
        } catch (error) {
            throw error;
        }
    };

    const register = async (name, email, password, password_confirmation) => {
        try {
            const response = await axios.post("/api/register", {
                name,
                email,
                password,
                password_confirmation,
            });
            
            setUser(response.data.user);
            setToken(response.data.token);
            localStorage.setItem("token", response.data.token);
            axios.defaults.headers.common["Authorization"] = `Bearer ${response.data.token}`;
            
            return response.data;
        } catch (error) {
            throw error;
        }
    };

    const logout = async () => {
        if (token) {
            try {
                await axios.post("/api/logout");
            } catch (error) {
                console.error("Logout error:", error);
            }
        }
        
        setUser(null);
        setToken(null);
        localStorage.removeItem("token");
        delete axios.defaults.headers.common["Authorization"];
    };

    return (
        <AuthContext.Provider
            value={{
                user,
                token,
                loading,
                login,
                register,
                logout,
            }}
        >
            {children}
        </AuthContext.Provider>
    );
};
EOF'

# Create cart context
docker-compose exec app bash -c 'cat > resources/js/contexts/CartContext.js << "EOF"
import React, { createContext, useState, useEffect } from "react";

export const CartContext = createContext();

export const CartProvider = ({ children }) => {
    const [cart, setCart] = useState([]);
    const [total, setTotal] = useState(0);

    useEffect(() => {
        // Load cart from localStorage
        const savedCart = localStorage.getItem("cart");
        if (savedCart) {
            try {
                setCart(JSON.parse(savedCart));
            } catch (e) {
                console.error("Error parsing cart:", e);
                setCart([]);
            }
        }
    }, []);

    useEffect(() => {
        // Calculate total
        const newTotal = cart.reduce(
            (sum, item) => sum + item.price * item.quantity,
            0
        );
        setTotal(newTotal);

        // Save cart to localStorage
        localStorage.setItem("cart", JSON.stringify(cart));
    }, [cart]);

    const addToCart = (product, quantity) => {
        setCart((prevCart) => {
            const existingItem = prevCart.find(
                (item) => item.product_id === product.id
            );

            if (existingItem) {
                return prevCart.map((item) =>
                    item.product_id === product.id
                        ? { ...item, quantity: item.quantity + quantity }
                        : item
                );
            } else {
                return [
                    ...prevCart,
                    {
                        product_id: product.id,
                        name: product.name,
                        price: product.price,
                        quantity,
                    },
                ];
            }
        });
    };

    const removeFromCart = (productId) => {
        setCart((prevCart) =>
            prevCart.filter((item) => item.product_id !== productId)
        );
    };

    const updateQuantity = (productId, quantity) => {
        if (quantity <= 0) {
            removeFromCart(productId);
            return;
        }

        setCart((prevCart) =>
            prevCart.map((item) =>
                item.product_id === productId
                    ? { ...item, quantity }
                    : item
            )
        );
    };

    const clearCart = () => {
        setCart([]);
        localStorage.removeItem("cart");
    };

    return (
        <CartContext.Provider
            value={{
                cart,
                total,
                addToCart,
                removeFromCart,
                updateQuantity,
                clearCart,
            }}
        >
            {children}
        </CartContext.Provider>
    );
};
EOF'

# Create protected route component
docker-compose exec app bash -c 'cat > resources/js/components/ProtectedRoute.js << "EOF"
import React, { useContext } from "react";
import { Navigate } from "react-router-dom";
import { AuthContext } from "../contexts/AuthContext";
import { Box, CircularProgress } from "@mui/material";

export default function ProtectedRoute({ children }) {
    const { user, loading } = useContext(AuthContext);

    if (loading) {
        return (
            <Box
                display="flex"
                justifyContent="center"
                alignItems="center"
                minHeight="100vh"
            >
                <CircularProgress />
            </Box>
        );
    }

    if (!user) {
        return <Navigate to="/login" />;
    }

    return children;
}
EOF'

echo "Frontend implementation script created." 
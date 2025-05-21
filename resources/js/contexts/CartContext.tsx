import React, { createContext, useState, useEffect, useContext, ReactNode } from 'react';

export interface Product {
    id: number;
    name: string;
    description: string;
    price: number;
    category: string;
    stock: number;
    image?: string;
}

export interface CartItem {
    product_id: number;
    name: string;
    price: number;
    quantity: number;
}

interface CartContextType {
    cart: CartItem[];
    total: number;
    addToCart: (product: Product, quantity: number) => void;
    removeFromCart: (productId: number) => void;
    updateQuantity: (productId: number, quantity: number) => void;
    clearCart: () => void;
}

interface CartProviderProps {
    children: ReactNode;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function useCart(): CartContextType {
    const context = useContext(CartContext);
    if (context === undefined) {
        throw new Error('useCart must be used within a CartProvider');
    }
    return context;
}

export default function CartProvider({ children }: CartProviderProps) {
    const [cart, setCart] = useState<CartItem[]>([]);
    const [total, setTotal] = useState(0);

    useEffect(() => {
        // Load cart from localStorage
        const savedCart = localStorage.getItem('cart');
        if (savedCart) {
            try {
                setCart(JSON.parse(savedCart));
            } catch (e) {
                console.error('Error parsing cart:', e);
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
        localStorage.setItem('cart', JSON.stringify(cart));
    }, [cart]);

    const addToCart = (product: Product, quantity: number) => {
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

    const removeFromCart = (productId: number) => {
        setCart((prevCart) =>
            prevCart.filter((item) => item.product_id !== productId)
        );
    };

    const updateQuantity = (productId: number, quantity: number) => {
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
        localStorage.removeItem('cart');
    };

    const value: CartContextType = {
        cart,
        total,
        addToCart,
        removeFromCart,
        updateQuantity,
        clearCart
    };

    return (
        <CartContext.Provider value={value}>
            {children}
        </CartContext.Provider>
    );
} 
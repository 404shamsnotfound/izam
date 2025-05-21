// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Container, Box, Typography, Grid, Card, CardContent, CardMedia, CardActions, 
         Button, AppBar, Toolbar, IconButton, Badge, TextField, MenuItem, 
         CircularProgress, Pagination, Alert } from '@mui/material';
import { ShoppingCart as ShoppingCartIcon, Logout as LogoutIcon } from '@mui/icons-material';
import axios from 'axios';
import { useAuth } from '../contexts/AuthContext';
import { useCart, CartItem } from '../contexts/CartContext';

// Define MUI Grid props including item prop
import type { GridProps } from '@mui/material';
interface ExtendedGridProps extends GridProps {
    item?: boolean;
}
// Type assertion helper function for Grid
const GridItem = Grid as React.ComponentType<ExtendedGridProps>;

// Define Product type
interface Product {
    id: number;
    name: string;
    description: string;
    price: number;
    category: string;
    stock: number;
    image?: string;
}

// Define params interface
interface ProductParams {
    page: number;
    name?: string;
    category?: string;
    min_price?: string;
    max_price?: string;
}

export default function ProductsPage() {
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [nameFilter, setNameFilter] = useState('');
    const [categoryFilter, setCategoryFilter] = useState('');
    const [minPrice, setMinPrice] = useState('');
    const [maxPrice, setMaxPrice] = useState('');
    const [categories, setCategories] = useState<string[]>([]);
    
    const { logout, user } = useAuth();
    const { addToCart, cart } = useCart();
    const navigate = useNavigate();
    
    useEffect(() => {
        fetchProducts();
    }, [page, nameFilter, categoryFilter, minPrice, maxPrice]);
    
    const fetchProducts = async () => {
        setLoading(true);
        try {
            let params: ProductParams = { page };
            
            if (nameFilter) params.name = nameFilter;
            if (categoryFilter) params.category = categoryFilter;
            if (minPrice) params.min_price = minPrice;
            if (maxPrice) params.max_price = maxPrice;
            
            const response = await axios.get('/api/products', { params });
            setProducts(response.data.data as Product[]);
            
            // Fix pagination by checking for meta.last_page or just last_page
            if (response.data.meta && response.data.meta.last_page) {
                setTotalPages(response.data.meta.last_page);
            } else if (response.data.last_page) {
                setTotalPages(response.data.last_page);
            } else {
                // Fallback to 1 if no pagination info is available
                setTotalPages(1);
            }
            
            // Extract unique categories for filter dropdown
            if (!categoryFilter && response.data.data.length > 0) {
                const uniqueCategories = [...new Set(response.data.data.map((p: Product) => p.category))] as string[];
                setCategories(uniqueCategories);
            }
        } catch (err) {
            setError('Failed to load products. Please try again later.');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };
    
    const handleAddToCart = (product: Product) => {
        addToCart(product, 1);
    };
    
    const handleLogout = async () => {
        try {
            await logout();
            navigate('/login');
        } catch (err) {
            console.error('Logout failed:', err);
        }
    };
    
    const viewCart = () => {
        // In a real app, navigate to cart page
        alert('Cart items: ' + cart.map((item: CartItem) => `${item.name} (${item.quantity})`).join(', '));
    };
    
    const handlePageChange = (_event: React.ChangeEvent<unknown>, value: number) => {
        setPage(value);
        window.scrollTo(0, 0);
    };
    
    return (
        <>
            <AppBar position="static">
                <Toolbar>
                    <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                        IZAM E-commerce
                    </Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Typography variant="body1" sx={{ mr: 2 }}>
                            Welcome, {user?.name}
                        </Typography>
                        <IconButton color="inherit" onClick={viewCart}>
                            <Badge badgeContent={cart.reduce((sum: number, item: CartItem) => sum + item.quantity, 0)} color="error">
                                <ShoppingCartIcon />
                            </Badge>
                        </IconButton>
                        <IconButton color="inherit" onClick={handleLogout}>
                            <LogoutIcon />
                        </IconButton>
                    </Box>
                </Toolbar>
            </AppBar>
            
            <Container maxWidth="lg" sx={{ mt: 4 }}>
                <Typography variant="h4" gutterBottom>
                    Products
                </Typography>
                
                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
                
                <Box sx={{ mb: 4 }}>
                    <Grid container spacing={2}>
                        <Grid item xs={12} sm={4} component="div">
                            <TextField
                                label="Search by name"
                                fullWidth
                                value={nameFilter}
                                onChange={(e) => setNameFilter(e.target.value)}
                                variant="outlined"
                            />
                        </Grid>
                        <Grid item xs={12} sm={3} component="div">
                            <TextField
                                select
                                label="Category"
                                fullWidth
                                value={categoryFilter}
                                onChange={(e) => setCategoryFilter(e.target.value)}
                                variant="outlined"
                            >
                                <MenuItem value="">All Categories</MenuItem>
                                {categories.map((category) => (
                                    <MenuItem key={category} value={category}>
                                        {category}
                                    </MenuItem>
                                ))}
                            </TextField>
                        </Grid>
                        <Grid item xs={12} sm={2} component="div">
                            <TextField
                                label="Min Price"
                                type="number"
                                fullWidth
                                value={minPrice}
                                onChange={(e) => setMinPrice(e.target.value)}
                                InputProps={{ inputProps: { min: 0 } }}
                                variant="outlined"
                            />
                        </Grid>
                        <Grid item xs={12} sm={2} component="div">
                            <TextField
                                label="Max Price"
                                type="number"
                                fullWidth
                                value={maxPrice}
                                onChange={(e) => setMaxPrice(e.target.value)}
                                InputProps={{ inputProps: { min: 0 } }}
                                variant="outlined"
                            />
                        </Grid>
                        <Grid item xs={12} sm={1} component="div">
                            <Button 
                                variant="contained" 
                                fullWidth 
                                sx={{ height: '100%' }}
                                onClick={() => {
                                    setNameFilter('');
                                    setCategoryFilter('');
                                    setMinPrice('');
                                    setMaxPrice('');
                                }}
                            >
                                Clear
                            </Button>
                        </Grid>
                    </Grid>
                </Box>
                
                {loading ? (
                    <Box sx={{ display: 'flex', justifyContent: 'center', my: 4 }}>
                        <CircularProgress />
                    </Box>
                ) : (
                    <>
                        <Grid container spacing={3}>
                            {products.map((product) => (
                                <GridItem item xs={12} sm={6} md={4} key={product.id} component="div">
                                    <Card>
                                        <CardMedia
                                            component="img"
                                            height="200"
                                            image={product.image || "https://via.placeholder.com/300"}
                                            alt={product.name}
                                        />
                                        <CardContent>
                                            <Typography gutterBottom variant="h6" component="div">
                                                {product.name}
                                            </Typography>
                                            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                                                {product.description.substring(0, 100)}...
                                            </Typography>
                                            <Typography variant="h6" color="primary">
                                                ${product.price}
                                            </Typography>
                                            <Typography variant="body2" color="text.secondary">
                                                Category: {product.category}
                                            </Typography>
                                            <Typography variant="body2" color="text.secondary">
                                                In stock: {product.stock}
                                            </Typography>
                                        </CardContent>
                                        <CardActions>
                                            <Button 
                                                size="small" 
                                                variant="contained" 
                                                fullWidth
                                                disabled={product.stock <= 0}
                                                onClick={() => handleAddToCart(product)}
                                            >
                                                {product.stock <= 0 ? 'Out of Stock' : 'Add to Cart'}
                                            </Button>
                                        </CardActions>
                                    </Card>
                                </GridItem>
                            ))}
                        </Grid>
                        
                        {products.length === 0 && !loading && (
                            <Box sx={{ my: 4, textAlign: 'center' }}>
                                <Typography variant="h6">No products found</Typography>
                            </Box>
                        )}
                        
                        <Box sx={{ display: 'flex', justifyContent: 'center', my: 4 }}>
                            <Pagination 
                                count={totalPages} 
                                page={page} 
                                onChange={handlePageChange} 
                                color="primary" 
                            />
                        </Box>
                    </>
                )}
            </Container>
        </>
    );
} 
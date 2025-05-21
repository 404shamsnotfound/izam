import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { Container, Box, Typography, Paper, Table, TableBody, TableCell, TableContainer, 
         TableHead, TableRow, Button, CircularProgress, Alert, Chip } from '@mui/material';
import axios from 'axios';
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material';

export default function OrderDetailsPage() {
    const [order, setOrder] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const { id } = useParams();
    const navigate = useNavigate();
    
    useEffect(() => {
        fetchOrderDetails();
    }, [id]);
    
    const fetchOrderDetails = async () => {
        setLoading(true);
        try {
            const response = await axios.get(`/api/orders/${id}`);
            setOrder(response.data);
        } catch (err) {
            setError(
                err.response?.status === 403 
                    ? 'You do not have permission to view this order.' 
                    : 'Failed to load order details. Please try again later.'
            );
            console.error(err);
        } finally {
            setLoading(false);
        }
    };
    
    const getStatusColor = (status) => {
        switch (status) {
            case 'pending':
                return 'warning';
            case 'processing':
                return 'info';
            case 'completed':
                return 'success';
            case 'cancelled':
                return 'error';
            default:
                return 'default';
        }
    };
    
    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
                <CircularProgress />
            </Box>
        );
    }
    
    if (error) {
        return (
            <Container maxWidth="md" sx={{ mt: 4 }}>
                <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>
                <Button 
                    startIcon={<ArrowBackIcon />} 
                    onClick={() => navigate('/products')}
                >
                    Back to Products
                </Button>
            </Container>
        );
    }
    
    return (
        <Container maxWidth="md" sx={{ my: 4 }}>
            <Button 
                startIcon={<ArrowBackIcon />} 
                component={Link} 
                to="/products" 
                sx={{ mb: 3 }}
            >
                Back to Products
            </Button>
            
            <Typography variant="h4" gutterBottom>
                Order #{order?.id}
            </Typography>
            
            <Box sx={{ mb: 4 }}>
                <Paper sx={{ p: 3, mb: 3 }}>
                    <Typography variant="h6" gutterBottom>
                        Order Summary
                    </Typography>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Box>
                            <Typography variant="body1">
                                Date: {new Date(order?.created_at).toLocaleDateString()}
                            </Typography>
                            <Typography variant="body1">
                                Total: ${order?.total}
                            </Typography>
                        </Box>
                        <Chip 
                            label={order?.status.toUpperCase()} 
                            color={getStatusColor(order?.status)} 
                            variant="outlined" 
                        />
                    </Box>
                </Paper>
                
                <Typography variant="h6" gutterBottom>
                    Order Items
                </Typography>
                
                <TableContainer component={Paper}>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Product</TableCell>
                                <TableCell align="right">Price</TableCell>
                                <TableCell align="right">Quantity</TableCell>
                                <TableCell align="right">Subtotal</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {order?.items.map((item) => (
                                <TableRow key={item.id}>
                                    <TableCell>
                                        <Typography variant="body1">
                                            {item.product.name}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary">
                                            {item.product.category}
                                        </Typography>
                                    </TableCell>
                                    <TableCell align="right">${item.price}</TableCell>
                                    <TableCell align="right">{item.quantity}</TableCell>
                                    <TableCell align="right">${(item.price * item.quantity).toFixed(2)}</TableCell>
                                </TableRow>
                            ))}
                            <TableRow>
                                <TableCell colSpan={3} align="right">
                                    <Typography variant="subtitle1">Total:</Typography>
                                </TableCell>
                                <TableCell align="right">
                                    <Typography variant="subtitle1">${order?.total}</Typography>
                                </TableCell>
                            </TableRow>
                        </TableBody>
                    </Table>
                </TableContainer>
            </Box>
        </Container>
    );
} 
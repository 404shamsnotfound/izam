import './bootstrap';
import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App.jsx';

// Create root element
const container = document.getElementById('app');
const root = createRoot(container);

// Render the app
root.render(
    React.createElement(BrowserRouter, null, 
        React.createElement(App, null)
    )
);

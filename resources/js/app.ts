import './bootstrap';
import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App.tsx';

// Create root element
const container = document.getElementById('app');

if (!container) {
  throw new Error('Root element not found');
}

const root = createRoot(container);

// Render the app
root.render(
  React.createElement(BrowserRouter, null, 
    React.createElement(App, null)
  )
); 
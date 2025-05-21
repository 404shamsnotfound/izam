<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>IZAM E-commerce</title>
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    @php
    $manifestPath = public_path('build/manifest.json');
    $assets = [];
    
    if (file_exists($manifestPath)) {
        $manifest = json_decode(file_get_contents($manifestPath), true);
        $cssFile = $manifest['resources/css/app.css']['file'] ?? null;
        $jsFile = $manifest['resources/js/app.ts']['file'] ?? null;
        
        if ($cssFile) echo '<link rel="stylesheet" href="/build/'.$cssFile.'">';
        if ($jsFile) echo '<script type="module" src="/build/'.$jsFile.'" defer></script>';
    }
    @endphp
</head>
<body>
    <div id="app"></div>
</body>
</html>

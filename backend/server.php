<?php

$publicPath = getcwd();
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '');

if ($uri !== '/' && file_exists($publicPath.$uri)) {
    if (str_starts_with($uri, '/storage/')) {
        $storagePath = realpath($publicPath.'/storage');
        $filePath = realpath($publicPath.$uri);
        $storagePrefix = $storagePath === false
            ? ''
            : strtolower($storagePath.DIRECTORY_SEPARATOR);

        if (
            $filePath !== false
            && is_file($filePath)
            && $storagePrefix !== ''
            && str_starts_with(strtolower($filePath), $storagePrefix)
        ) {
            $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

            if (preg_match('/^http:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/D', $origin)) {
                header("Access-Control-Allow-Origin: {$origin}");
                header('Vary: Origin');
            }

            $contentType = mime_content_type($filePath);
            header('Content-Type: '.($contentType ?: 'application/octet-stream'));

            $contentLength = filesize($filePath);
            if ($contentLength !== false) {
                header('Content-Length: '.$contentLength);
            }

            if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'HEAD') {
                readfile($filePath);
            }

            exit;
        }
    }

    return false;
}

require_once $publicPath.'/index.php';

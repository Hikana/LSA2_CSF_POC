<?php
session_start();
$db = new SQLite3('/var/www/html/users.db');
$upload_folder = 'static/uploads';
if (!file_exists($upload_folder)) mkdir($upload_folder, 0777, true);

function quote($str) {
    return urlencode($str);
}
function unquote($str) {
    return urldecode($str);
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);


if ($uri === '/' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    include('templates/login.php');
} elseif ($uri === '/login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];
    $query = "SELECT * FROM users WHERE username = '$username' AND password = '$password'";
    $res = $db->query($query);
    if ($res->fetchArray()) {
        $_SESSION['user'] = $username;
        header('Location: /dashboard');
    } else {
        echo "Login Failed";
    }
} elseif ($uri === '/dashboard') {
    if (!isset($_SESSION['user'])) {
        header('Location: /');
        exit;
    }
    $files = array_diff(scandir($upload_folder), ['.', '..']);
    include('templates/dashboard.php');
} elseif ($uri === '/upload' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_SESSION['user'])) {
        header('Location: /');
        exit;
    }
    $target = $upload_folder . '/' . basename($_FILES['file']['name']);
    move_uploaded_file($_FILES['file']['tmp_name'], $target);
    header('Location: /dashboard');
} elseif ($uri === '/file') {
    if (!isset($_SESSION['user'])) {
        header('Location: /');
        exit;
    }
    $query = parse_url($_SERVER['REQUEST_URI'], PHP_URL_QUERY);
    preg_match('/name=([^&]*)/', $query, $matches);
    $raw_name = $matches[1] ?? '';

    if (strpos(substr($raw_name, 16), '/') !== false || urldecode(substr($raw_name, 0, 3)) == "/" || urldecode(substr($raw_name, 0, 1) == "/") || $raw_name =="") {
        http_response_code(403);
        echo "ForbiddenXD";
        exit;
    }

    $name = urldecode($raw_name);

    function normalize_path($path) {
        $parts = [];
        $segments = explode('/', str_replace('\\', '/', $path));
        foreach ($segments as $segment) {
            if ($segment === '' || $segment === '.') continue;
            if ($segment === '..') {
                if (count($parts) > 0) array_pop($parts);
            } else {
                $parts[] = $segment;
            }
        }
        return '/' . implode('/', $parts);
    }

    $base_dir = __DIR__;
    $path = normalize_path($name);
    $full_path = $base_dir . $path;

    if (is_dir($full_path)) {
        $items = scandir($full_path);
        echo "<h2>Listing for {$path}</h2><ul>";

        $parent = dirname($path);
        if ($parent && $parent !== $path && $parent !== '/') {
            echo "<li><a href=\"/file?name=" . urlencode(ltrim($parent, '/')) . "\">[..]</a></li>";
        }

        foreach ($items as $item) {
            if ($item === '.' || $item === '..') continue;
            $item_path = rtrim($path, '/') . '/' . $item;
            $quoted = urlencode($item_path);
            if (is_dir($base_dir . $item_path)) {
                echo "<li>[DIR] <a href=\"/file?name={$quoted}\">" . htmlspecialchars($item) . "</a></li>";
            } else {
                echo "<li>[FILE] <a href=\"/file?name={$quoted}\">" . htmlspecialchars($item) . "</a></li>";
            }
        }
        echo "</ul>";

    } elseif (file_exists($full_path)) {
        $ext = pathinfo($full_path, PATHINFO_EXTENSION);
        if ($ext === 'php') {
            include $full_path;
        } else {
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mime = finfo_file($finfo, $full_path);
            finfo_close($finfo);
            header('Content-Type: ' . $mime);
            readfile($full_path);
        }
    } else {
        http_response_code(404);
        echo "File not found: $path";
    }
} elseif ($uri === '/debug_users') {
    $res = $db->query("SELECT username, password FROM users");
    $rows = [];
    while ($row = $res->fetchArray(SQLITE3_ASSOC)) {
        $rows[] = $row;
    }
    echo json_encode($rows);
} else {
    http_response_code(404);
    echo "Not Found";
}

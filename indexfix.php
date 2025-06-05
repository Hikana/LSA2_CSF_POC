<?php
session_start();
$db = new SQLite3('users.db');
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

    // ⚠️ 危險：以下為原本容易造成 SQL Injection 的寫法，應避免使用
    // $query = "SELECT * FROM users WHERE username = '$username' AND password = '$password'";
    // $res = $db->query($query);

    // ✅ 安全作法：使用 SQLite3 prepared statement 防止 SQL Injection
    $stmt = $db->prepare("SELECT * FROM users WHERE username = :username AND password = :password");
    $stmt->bindValue(':username', $username, SQLITE3_TEXT);
    $stmt->bindValue(':password', $password, SQLITE3_TEXT);

    $res = $stmt->execute();

    if ($res->fetchArray()) {
        // 登入成功，儲存 session 並導向 dashboard
        $_SESSION['user'] = $username;
        header('Location: /dashboard');
    } else {
        // 登入失敗，顯示錯誤訊息
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

    // 取得參數
    $query = parse_url($_SERVER['REQUEST_URI'], PHP_URL_QUERY);
    preg_match('/name=([^&]*)/', $query, $matches);
    $filename = $matches[1] ?? '';
    $filename = urldecode($filename);

    // ✅ 只允許單一檔名，避免使用者傳入路徑（像是 static/uploads/../config.php）
    if (basename($filename) !== $filename) {
        http_response_code(403);
        echo "Forbidden: invalid filename";
        exit;
    }

    // ✅ 限制只能從 uploads 資料夾存取檔案
    $upload_dir = __DIR__ . '/static/uploads/';
    $full_path = $upload_dir . $filename;

    // ✅ 檔案不存在就回 404
    if (!file_exists($full_path)) {
        http_response_code(404);
        echo "File not found";
        exit;
    }

    // ✅ 一律強制下載，不執行
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="' . basename($full_path) . '"');
    header('Content-Length: ' . filesize($full_path));
    readfile($full_path);
    exit;

    // ❌ 以下原本支援路徑瀏覽與 PHP 執行的部分都註解掉 -----------------------------------

    /*
    if (strpos(substr($raw_name, 16), '/') !== false || urldecode(substr($raw_name, 0, 3)) == "/" || urldecode(substr($raw_name, 0, 1) == "/") || $raw_name =="") {
        http_response_code(403);
        echo "ForbiddenXD";
        exit;
    }

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
    */
} 
// 這邊多餘的 api 不用留
// elseif ($uri === '/debug_users') {
//     $res = $db->query("SELECT username, password FROM users");
//     $rows = [];
//     while ($row = $res->fetchArray(SQLITE3_ASSOC)) {
//         $rows[] = $row;
//     }
//     echo json_encode($rows);
// } 
else {
    http_response_code(404);
    echo "Not Found";
}

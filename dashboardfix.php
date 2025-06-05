<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            min-height: 100vh;
            background: #000000;
            font-family: 'Arial', sans-serif;
            position: relative;
            overflow-x: hidden;
            color: #ffffff;
        }

        /* 頂部標題欄 */
        .header {
            background: #000000;
            padding: 20px 0;
            text-align: center;
            border-bottom: 3px solid #ff9900;
            position: relative;
            z-index: 10;
        }

        .logo {
            font-size: 2.5rem;
            font-weight: bold;
            color: #ffffff;
            text-decoration: none;
            display: inline-block;
        }

        .logo .orange {
            background: linear-gradient(135deg, #ff9900, #ffaa00);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .logo .white {
            color: #ffffff;
        }

        /* 主要內容區域 */
        .main-content {
            padding: 40px 20px;
            position: relative;
        }

        /* 背景網格效果 */
        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: 
                linear-gradient(rgba(255, 153, 0, 0.05) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255, 153, 0, 0.05) 1px, transparent 1px);
            background-size: 50px 50px;
            z-index: 1;
            pointer-events: none;
        }

        /* 橙色光暈效果 */
        .main-content::before {
            content: '';
            position: absolute;
            top: 20%;
            left: 50%;
            width: 800px;
            height: 400px;
            background: radial-gradient(ellipse, rgba(255, 153, 0, 0.1) 0%, transparent 70%);
            transform: translateX(-50%);
            animation: glow 6s ease-in-out infinite;
            z-index: 1;
            pointer-events: none;
        }

        @keyframes glow {
            0%, 100% { opacity: 0.1; transform: translateX(-50%) scale(1); }
            50% { opacity: 0.2; transform: translateX(-50%) scale(1.1); }
        }

        /* 內容容器 */
        .container {
            position: relative;
            z-index: 10;
            max-width: 800px;
            margin: 0 auto;
        }

        h2 {
            text-align: center;
            font-size: 2.5rem;
            font-weight: bold;
            color: #ffffff;
            margin-bottom: 40px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }

        h3 {
            color: #ff9900;
            font-size: 1.5rem;
            margin: 30px 0 20px 0;
            text-align: center;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 2px;
        }

        form {
            background: #1a1a1a;
            border: 2px solid #ff9900;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 
                0 0 30px rgba(255, 153, 0, 0.3),
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
            margin-bottom: 30px;
            color: #ffffff;
            font-weight: bold;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        input[type="file"] {
            width: 100%;
            padding: 15px;
            background: #000000;
            border: 2px solid #333333;
            border-radius: 4px;
            color: #ffffff;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        input[type="file"]:focus {
            outline: none;
            border-color: #ff9900;
            box-shadow: 0 0 15px rgba(255, 153, 0, 0.5);
            background: #111111;
        }

        input[type="file"]::-webkit-file-upload-button {
            background: linear-gradient(135deg, #ff9900, #ffaa00);
            border: none;
            border-radius: 4px;
            color: #000000;
            padding: 8px 16px;
            margin-right: 10px;
            cursor: pointer;
            font-weight: bold;
            text-transform: uppercase;
            font-size: 12px;
        }

        input[type="file"]::-webkit-file-upload-button:hover {
            background: linear-gradient(135deg, #ffaa00, #ffbb00);
        }

        input[type="submit"] {
            width: auto;
            align-self: flex-start;
            padding: 15px 30px;
            background: linear-gradient(135deg, #ff9900, #ffaa00);
            border: none;
            border-radius: 4px;
            color: #000000;
            font-size: 1rem;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        input[type="submit"]:hover {
            background: linear-gradient(135deg, #ffaa00, #ffbb00);
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(255, 153, 0, 0.4);
        }

        input[type="submit"]:active {
            transform: translateY(0);
        }

        ul {
            list-style: none;
            background: #1a1a1a;
            border: 2px solid #ff9900;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 
                0 0 30px rgba(255, 153, 0, 0.3),
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
        }

        li {
            background: #000000;
            border: 1px solid #333333;
            border-radius: 4px;
            padding: 15px 20px;
            margin-bottom: 10px;
            transition: all 0.3s ease;
        }

        li:hover {
            background: #111111;
            border-color: #ff9900;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(255, 153, 0, 0.2);
        }

        li a {
            color: #ff9900;
            text-decoration: none;
            font-size: 1.1rem;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: color 0.3s ease;
        }

        li a:hover {
            color: #ffaa00;
        }

        li a:before {
            content: '📁';
            font-size: 1.2rem;
        }

        /* 空狀態樣式 */
        ul:empty::after {
            content: 'No files uploaded yet';
            display: block;
            text-align: center;
            color: #666666;
            font-size: 1.1rem;
            padding: 40px;
            font-style: italic;
        }

        @media (max-width: 768px) {
            .logo {
                font-size: 2rem;
            }
            
            h2 {
                font-size: 2rem;
            }
            
            form {
                padding: 20px;
            }
            
            ul {
                padding: 20px;
            }
        }

        @media (max-width: 480px) {
            .logo {
                font-size: 1.8rem;
            }
            
            h2 {
                font-size: 1.8rem;
            }
            
            form {
                padding: 15px;
            }
            
            input[type="file"] {
                padding: 12px;
                font-size: 0.9rem;
            }
            
            input[type="submit"] {
                padding: 12px 25px;
                font-size: 0.9rem;
            }
        }
    </style>
</head>
<body>
    <!-- 頂部標題欄 -->
    <div class="header">
        <a href="#" class="logo">
            <span class="orange">File</span><span class="white">Hub</span>
        </a>
    </div>

    <!-- 主要內容 -->
    <div class="main-content">
        <div class="container">
            <h2>Welcome to the File Dashboard</h2>
            <form method="POST" enctype="multipart/form-data" action="/upload">
              Upload file: <input type="file" name="file">
              <input type="submit" value="Upload">
            </form>
            <h3>Files:</h3>
            <ul>
            <?php foreach ($files as $file): ?>
              <li><a href="/file?name=<?php echo $file; ?>"><?php echo $file; ?></a></li>
            <?php endforeach; ?>
            </ul>
        </div>
    </div>
</body>
</html>

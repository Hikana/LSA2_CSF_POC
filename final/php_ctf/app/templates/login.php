<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
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
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: calc(100vh - 100px);
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
            top: 50%;
            left: 50%;
            width: 600px;
            height: 600px;
            background: radial-gradient(circle, rgba(255, 153, 0, 0.15) 0%, transparent 70%);
            transform: translate(-50%, -50%);
            animation: pulse 4s ease-in-out infinite;
            z-index: 1;
            pointer-events: none;
        }

        @keyframes pulse {
            0%, 100% { transform: translate(-50%, -50%) scale(1); opacity: 0.15; }
            50% { transform: translate(-50%, -50%) scale(1.2); opacity: 0.25; }
        }

        /* 登錄容器 */
        .login-container {
            position: relative;
            z-index: 10;
            width: 100%;
            max-width: 450px;
        }

        h2 {
            text-align: center;
            font-size: 2rem;
            font-weight: bold;
            color: #ffffff;
            margin-bottom: 30px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }

        form {
            background: #1a1a1a;
            border: 2px solid #ff9900;
            border-radius: 8px;
            padding: 40px;
            box-shadow: 
                0 0 30px rgba(255, 153, 0, 0.3),
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
            color: #ffffff;
            font-weight: bold;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-label {
            display: block;
            color: #ffffff;
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 15px;
            background: #000000;
            border: 2px solid #333333;
            border-radius: 4px;
            color: #ffffff;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        input[type="text"]:focus, input[type="password"]:focus {
            outline: none;
            border-color: #ff9900;
            box-shadow: 0 0 15px rgba(255, 153, 0, 0.5);
            background: #111111;
        }

        input[type="text"]::placeholder, input[type="password"]::placeholder {
            color: #666666;
        }

        input[type="submit"] {
            width: 100%;
            padding: 18px;
            background: linear-gradient(135deg, #ff9900, #ffaa00);
            border: none;
            border-radius: 4px;
            color: #000000;
            font-size: 1.1rem;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 20px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }

        input[type="submit"]:hover {
            background: linear-gradient(135deg, #ffaa00, #ffbb00);
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(255, 153, 0, 0.4);
        }

        input[type="submit"]:active {
            transform: translateY(0);
        }

        /* 隱藏原始的 br 標籤 */
        br {
            display: none;
        }

        /* 底部鏈接 */
        .footer-links {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #333333;
        }

        .footer-links a {
            color: #ff9900;
            text-decoration: none;
            font-size: 14px;
            transition: color 0.3s ease;
        }

        .footer-links a:hover {
            color: #ffaa00;
            text-decoration: underline;
        }

        @media (max-width: 768px) {
            .logo {
                font-size: 2rem;
            }
            
            .main-content {
                padding: 20px;
            }
            
            form {
                padding: 30px 20px;
            }
            
            h2 {
                font-size: 1.5rem;
            }
        }

        @media (max-width: 480px) {
            .logo {
                font-size: 1.8rem;
            }
            
            form {
                padding: 25px 15px;
            }
            
            h2 {
                font-size: 1.3rem;
            }
            
            input[type="text"], input[type="password"] {
                padding: 12px;
                font-size: 0.9rem;
            }
            
            input[type="submit"] {
                padding: 15px;
                font-size: 1rem;
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
        <div class="login-container">
            <h2>Login</h2>
            <form method="POST" action="/login">
                <div class="form-group">
                    <label class="form-label">Username:</label>
                    <input type="text" name="username" placeholder="Enter your username">
                </div>
                <div class="form-group">
                    <label class="form-label">Password:</label>
                    <input type="password" name="password" placeholder="Enter your password">
                </div>
                <input type="submit" value="Login">
            </form>
        </div>
    </div>
</body>
</html>

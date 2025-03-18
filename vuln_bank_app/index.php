<?php
session_start();
?>
<!DOCTYPE html>
<html>
<head>
    <title>SecureBank - Votre banque en ligne</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; }
        header { background-color: #2c3e50; color: white; padding: 1em; text-align: center; }
        .container { width: 80%; margin: 0 auto; padding: 2em; }
        .login-form { background-color: white; padding: 2em; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        input[type=text], input[type=password] { width: 100%; padding: 12px 20px; margin: 8px 0; display: inline-block; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        button { background-color: #2c3e50; color: white; padding: 14px 20px; margin: 8px 0; border: none; border-radius: 4px; cursor: pointer; width: 100%; }
        button:hover { opacity: 0.8; }
    </style>
</head>
<body>
    <header>
        <h1>SecureBank</h1>
    </header>
    <div class="container">
        <div class="login-form">
            <h2>Connexion</h2>
            <?php
            // Simulation d'injection SQL
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                $username = $_POST['username'] ?? '';
                $password = $_POST['password'] ?? '';
                
                // Vulnérabilité simulée: pas de base de données réelle pour économiser les ressources
                if (($username === 'admin' && $password === 'password') || 
                    ($username === "admin' --" && $password === "anything") ||
                    ($username === "user" && $password === "password123")) {
                    
                    $_SESSION['user_id'] = 1;
                    $_SESSION['username'] = $username;
                    echo "<p style='color: green;'>Connexion réussie ! Bienvenue " . htmlspecialchars($username) . "</p>";
                } else {
                    echo "<p style='color: red;'>Identifiants incorrects.</p>";
                }
            }
            ?>
            <form method="post" action="">
                <label for="username">Nom d'utilisateur:</label>
                <input type="text" id="username" name="username" required>
                <label for="password">Mot de passe:</label>
                <input type="password" id="password" name="password" required>
                <button type="submit">Se connecter</button>
            </form>
            <p><small>Indice: essayez 'admin' -- ' comme nom d'utilisateur</small></p>
        </div>
    </div>
</body>
</html>

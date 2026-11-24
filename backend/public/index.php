<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function db(): PDO
{
    static $connection;
    if ($connection instanceof PDO) {
        return $connection;
    }

    $host = getenv('DB_HOST') ?: '127.0.0.1';
    $port = getenv('DB_PORT') ?: '3306';
    $database = getenv('DB_NAME') ?: 'projet_tp';
    $username = getenv('DB_USER') ?: 'root';
    $password = getenv('DB_PASSWORD') ?: '';
    $dsn = "mysql:host={$host};port={$port};dbname={$database};charset=utf8mb4";
    $connection = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    return $connection;
}

function input(): array
{
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (str_contains($contentType, 'application/json')) {
        $decoded = json_decode(file_get_contents('php://input') ?: '', true);
        if (!is_array($decoded)) {
            respond(400, ['error' => 'Corps JSON invalide.']);
        }
        return $decoded;
    }
    return $_POST;
}

function issueToken(PDO $pdo, int $userId): string
{
    $token = bin2hex(random_bytes(32));
    $statement = $pdo->prepare(
        'INSERT INTO api_tokens (user_id, token_hash, expires_at)
         VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))'
    );
    $statement->execute([$userId, hash('sha256', $token)]);
    return $token;
}

function authenticatedUser(PDO $pdo): array
{
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $authorization = $headers['Authorization'] ?? $headers['authorization'] ??
        ($_SERVER['HTTP_AUTHORIZATION'] ?? '');
    if (!preg_match('/^Bearer ([a-f0-9]{64})$/i', $authorization, $matches)) {
        respond(401, ['error' => 'Authentification requise.']);
    }

    $statement = $pdo->prepare(
        'SELECT u.id, u.name, u.email, t.id AS token_id
         FROM api_tokens t
         JOIN users u ON u.id = t.user_id
         WHERE t.token_hash = ? AND t.expires_at > NOW()'
    );
    $statement->execute([hash('sha256', $matches[1])]);
    $user = $statement->fetch();
    if (!$user) {
        respond(401, ['error' => 'Session expirée. Reconnectez-vous.']);
    }
    return $user;
}

function userData(array $user): array
{
    return ['id' => (int) $user['id'], 'name' => $user['name'], 'email' => $user['email']];
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $requestPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    if (preg_match('#^/uploads/([a-f0-9]{32}\.(?:jpg|png|webp))$#i', $requestPath, $matches)) {
        $photoPath = __DIR__ . '/uploads/' . $matches[1];
        if (is_file($photoPath)) {
            $mimeTypes = ['jpg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp'];
            $extension = strtolower(pathinfo($photoPath, PATHINFO_EXTENSION));
            header('Content-Type: ' . $mimeTypes[$extension]);
            header('Content-Length: ' . filesize($photoPath));
            header('Cache-Control: private, max-age=86400');
            readfile($photoPath);
            exit;
        }
    }
}

function savePhoto(): ?string
{
    if (!isset($_FILES['photo'])) {
        return null;
    }
    $file = $_FILES['photo'];
    if ($file['error'] !== UPLOAD_ERR_OK) {
        respond(400, ['error' => 'Le transfert de la photo a échoué.']);
    }
    if ($file['size'] > 5 * 1024 * 1024) {
        respond(413, ['error' => 'La photo ne peut pas dépasser 5 Mo.']);
    }

    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    $extensions = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];
    if (!isset($extensions[$mime]) || @getimagesize($file['tmp_name']) === false) {
        respond(415, ['error' => 'Format photo non accepté (JPEG, PNG ou WebP).']);
    }

    $uploadDirectory = __DIR__ . '/uploads';
    if (!is_dir($uploadDirectory) &&
        !mkdir($uploadDirectory, 0755, true) &&
        !is_dir($uploadDirectory)) {
        respond(500, ['error' => 'Le dossier de photos est indisponible.']);
    }
    $filename = bin2hex(random_bytes(16)) . '.' . $extensions[$mime];
    if (!move_uploaded_file($file['tmp_name'], $uploadDirectory . '/' . $filename)) {
        respond(500, ['error' => 'Impossible d’enregistrer la photo.']);
    }
    return '/uploads/' . $filename;
}

try {
    $pdo = db();
    $method = $_SERVER['REQUEST_METHOD'];
    $path = trim(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/', '/');
    $segments = $path === '' ? [] : explode('/', $path);

    if (($segments[0] ?? '') === 'auth' && ($segments[1] ?? '') === 'register' && $method === 'POST') {
        $body = input();
        $name = trim((string) ($body['name'] ?? ''));
        $email = strtolower(trim((string) ($body['email'] ?? '')));
        $password = (string) ($body['password'] ?? '');
        if (mb_strlen($name) < 2 || mb_strlen($name) > 120 ||
            strlen($email) > 190 || !filter_var($email, FILTER_VALIDATE_EMAIL) ||
            strlen($password) < 8 || strlen($password) > 1024) {
            respond(422, ['error' => 'Nom, adresse e-mail ou mot de passe invalide.']);
        }
        $statement = $pdo->prepare(
            'INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)'
        );
        try {
            $statement->execute([$name, $email, password_hash($password, PASSWORD_DEFAULT)]);
        } catch (PDOException $error) {
            if ($error->getCode() === '23000') {
                respond(409, ['error' => 'Cette adresse e-mail possède déjà un compte.']);
            }
            throw $error;
        }
        $userId = (int) $pdo->lastInsertId();
        $token = issueToken($pdo, $userId);
        respond(201, ['data' => [
            'token' => $token,
            'user' => ['id' => $userId, 'name' => $name, 'email' => $email],
        ]]);
    }

    if (($segments[0] ?? '') === 'auth' && ($segments[1] ?? '') === 'login' && $method === 'POST') {
        $body = input();
        $email = strtolower(trim((string) ($body['email'] ?? '')));
        $password = (string) ($body['password'] ?? '');
        $statement = $pdo->prepare('SELECT id, name, email, password_hash FROM users WHERE email = ?');
        $statement->execute([$email]);
        $user = $statement->fetch();
        if (!$user || !password_verify($password, $user['password_hash'])) {
            respond(401, ['error' => 'Adresse e-mail ou mot de passe incorrect.']);
        }
        respond(200, ['data' => [
            'token' => issueToken($pdo, (int) $user['id']),
            'user' => userData($user),
        ]]);
    }

    if (($segments[0] ?? '') === 'auth' && ($segments[1] ?? '') === 'logout' && $method === 'POST') {
        $user = authenticatedUser($pdo);
        $statement = $pdo->prepare('DELETE FROM api_tokens WHERE id = ?');
        $statement->execute([$user['token_id']]);
        respond(200, ['data' => ['message' => 'Déconnexion réussie.']]);
    }

    if (in_array($segments[0] ?? '', ['family', 'students'], true)) {
        $user = authenticatedUser($pdo);
        $family = $segments[0] === 'family';
        $table = $family ? 'family_members' : 'students';
        if (count($segments) > 2) {
            respond(404, ['error' => 'Route introuvable.']);
        }
        $id = null;
        if (isset($segments[1])) {
            if (!ctype_digit($segments[1]) || (int) $segments[1] < 1) {
                respond(404, ['error' => 'Dossier introuvable.']);
            }
            $id = (int) $segments[1];
        }

        if ($method === 'GET' && $id === null) {
            $statement = $pdo->prepare("SELECT * FROM {$table} WHERE user_id = ? ORDER BY created_at DESC");
            $statement->execute([$user['id']]);
            respond(200, ['data' => ['items' => $statement->fetchAll()]]);
        }

        if ($method === 'POST') {
            $body = input();
            $firstName = trim((string) ($body['first_name'] ?? ''));
            $lastName = trim((string) ($body['last_name'] ?? ''));
            if ($firstName === '' || $lastName === '' ||
                mb_strlen($firstName) > 100 || mb_strlen($lastName) > 100) {
                respond(422, ['error' => 'Le nom et le prénom sont obligatoires.']);
            }
            $phone = trim((string) ($body['phone'] ?? ''));
            $relationship = trim((string) ($body['relationship'] ?? ''));
            $schoolClass = trim((string) ($body['school_class'] ?? ''));
            $address = trim((string) ($body['address'] ?? ''));
            if (strlen($phone) > 40 ||
                ($family && mb_strlen($relationship) > 80) ||
                (!$family && (mb_strlen($schoolClass) > 120 || mb_strlen($address) > 255))) {
                respond(422, ['error' => 'Une ou plusieurs informations sont trop longues.']);
            }
            $birthday = trim((string) ($body['birthday'] ?? ''));
            if ($birthday !== '') {
                $date = DateTime::createFromFormat('!Y-m-d', $birthday);
                if (!$date || $date->format('Y-m-d') !== $birthday) {
                    respond(422, ['error' => 'Date de naissance invalide.']);
                }
            } else {
                $birthday = null;
            }
            $photoUrl = savePhoto();
            $fields = [
                'first_name' => $firstName,
                'last_name' => $lastName,
                'phone' => $phone,
                'birthday' => $birthday,
                'photo_url' => $photoUrl,
            ];
            if ($family) {
                $fields['relationship'] = $relationship;
            } else {
                $fields['school_class'] = $schoolClass;
                $fields['address'] = $address;
            }

            if ($id === null) {
                $fields['user_id'] = (int) $user['id'];
                $columns = array_keys($fields);
                $sql = "INSERT INTO {$table} (" . implode(', ', $columns) . ")
                        VALUES (" . implode(', ', array_fill(0, count($columns), '?')) . ')';
                $statement = $pdo->prepare($sql);
                $statement->execute(array_values($fields));
                respond(201, ['data' => ['id' => (int) $pdo->lastInsertId()]]);
            }

            if ($photoUrl === null) {
                unset($fields['photo_url']);
            }
            $assignments = array_map(
                static fn(string $column): string => "{$column} = ?",
                array_keys($fields)
            );
            $statement = $pdo->prepare(
                "UPDATE {$table} SET " . implode(', ', $assignments) . ' WHERE id = ? AND user_id = ?'
            );
            $statement->execute([...array_values($fields), $id, $user['id']]);
            if ($statement->rowCount() === 0) {
                $check = $pdo->prepare("SELECT id FROM {$table} WHERE id = ? AND user_id = ?");
                $check->execute([$id, $user['id']]);
                if (!$check->fetch()) {
                    respond(404, ['error' => 'Dossier introuvable.']);
                }
            }
            respond(200, ['data' => ['id' => $id]]);
        }

        if ($method === 'DELETE' && $id !== null) {
            $statement = $pdo->prepare("DELETE FROM {$table} WHERE id = ? AND user_id = ?");
            $statement->execute([$id, $user['id']]);
            if ($statement->rowCount() === 0) {
                respond(404, ['error' => 'Dossier introuvable.']);
            }
            respond(200, ['data' => ['message' => 'Dossier supprimé.']]);
        }
    }

    respond(404, ['error' => 'Route introuvable.']);
} catch (Throwable $error) {
    error_log((string) $error);
    respond(500, ['error' => 'Erreur interne du serveur. Vérifiez la configuration PHP et MySQL.']);
}

<?php
// monica-setup: run by the monica-setup container (the Monica image itself) on
// every `docker compose up`. Idempotent:
//   1. no account yet  → create it from MONICA_EMAIL / MONICA_PASSWORD
//   2. no personal access client → create one (Passport)
//   3. no valid token in /data/mcp/token (missing, revoked, deleted, or
//      expiring within 30 days), or MONICA_SETUP_ROTATE=1 → create one, and
//      revoke the token it replaces
// The token file is readable by uid 1000 only (the MCP container's user).

const TOKEN_FILE = '/data/mcp/token';
const TOKEN_NAME = 'monica-mcp';

require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User\User;
use Illuminate\Support\Facades\Artisan;
use Laravel\Passport\Client;
use Laravel\Passport\Token;

function say(string $line): void
{
    fwrite(STDOUT, "monica-setup: $line\n");
}

function fail(string $line): never
{
    fwrite(STDERR, "monica-setup: $line\n");
    exit(1);
}

// 1. the first account
$user = User::orderBy('id')->first();
if (!$user) {
    $email = getenv('MONICA_EMAIL') ?: '';
    $password = getenv('MONICA_PASSWORD') ?: '';
    if ($email === '' || strlen($password) < 8) {
        fail('no account yet: set MONICA_EMAIL and MONICA_PASSWORD (8+ characters) in .env, then docker compose up -d');
    }
    Artisan::call('setup:production', ['--force' => true, '--email' => $email, '--password' => $password, '--no-interaction' => true]);
    $user = User::orderBy('id')->first() ?? fail('creating the account failed: ' . trim(Artisan::output()));
    // Monica starts every account as John Doe, America/Chicago, US dollars
    $tz = getenv('TZ') ?: '';
    if ($tz !== '' && in_array($tz, timezone_identifiers_list(), true)) {
        $user->timezone = $tz;
    }
    $name = trim(getenv('MONICA_NAME') ?: '');
    if ($name !== '') {
        $parts = preg_split('/\s+/', $name, 2);
        $user->first_name = $parts[0];
        $user->last_name = $parts[1] ?? '';
    }
    $currency = App\Models\Settings\Currency::where('iso', strtoupper(getenv('MONICA_CURRENCY') ?: ''))->first();
    if ($currency) {
        $user->currency_id = $currency->id;
    }
    $user->save();
    say("created the account $email (timezone {$user->timezone})");
} else {
    say("account: {$user->email}");
}

// 2. Passport's keys (Monica's own start-up makes them) and personal client
if (!file_exists(storage_path('oauth-private.key'))) {
    Artisan::call('passport:keys', ['--no-interaction' => true]);
}
if (!Client::where('personal_access_client', true)->where('revoked', false)->exists()) {
    Artisan::call('passport:client', ['--personal' => true, '--name' => TOKEN_NAME, '--no-interaction' => true]);
    say('created the personal access client');
}

// 3. the MCP's token
function token_id(string $jwt): ?string
{
    $parts = explode('.', trim($jwt));
    if (count($parts) !== 3) {
        return null;
    }
    $claims = json_decode(base64_decode(strtr($parts[1], '-_', '+/')), true);
    return is_array($claims) ? ($claims['jti'] ?? null) : null;
}

$current = is_readable(TOKEN_FILE) ? trim((string) file_get_contents(TOKEN_FILE)) : '';
$id = $current !== '' ? token_id($current) : null;
$token = $id ? Token::find($id) : null;
$reason = match (true) {
    getenv('MONICA_SETUP_ROTATE') === '1' => 'replacing it, as asked',
    $current === '' => 'none yet',
    !$token => 'the saved one no longer exists in Monica',
    (bool) $token->revoked => 'the saved one was revoked',
    $token->expires_at !== null && $token->expires_at->lt(now()->addDays(30)) => 'the saved one expires on ' . $token->expires_at->toDateString(),
    default => null,
};

if ($reason === null) {
    say('MCP token: valid until ' . ($token->expires_at?->toDateString() ?? 'no expiry'));
    exit(0);
}

$new = $user->createToken(TOKEN_NAME)->accessToken;
@mkdir(dirname(TOKEN_FILE), 0700, true);
$tmp = TOKEN_FILE . '.tmp';
file_put_contents($tmp, $new . "\n");
chmod($tmp, 0600);
chown($tmp, 1000);
chgrp($tmp, 1000);
rename($tmp, TOKEN_FILE);
if ($token && !$token->revoked) {
    $token->revoke();
}
say("MCP token: created ($reason)");

<?php

declare(strict_types=1);

/**
 * The AI page has a provider named "OpenRouter" and a model whose id is
 * "openrouter/free". Typing the provider's name into the Model ID box is an
 * easy mistake, and it used to be accepted — the failure only showed up later
 * as a wall of JSON from the provider. These guard both ends of that.
 */

use App\Models\User;
use Cartxis\Core\Services\SettingService;
use Cartxis\Product\Models\Product;
use Cartxis\Product\Services\AiProductDescriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

function aiAdmin(): User
{
    return User::factory()->withoutTwoFactor()->create([
        'role' => 'admin',
        'is_active' => true,
    ]);
}

function configureOpenRouter(): void
{
    $settings = app(SettingService::class);
    $settings->set('ai.enabled', true, 'boolean', 'ai');
    $settings->set('ai.providers', [[
        'name' => 'OpenRouter',
        'type' => 'custom',
        'base_url' => 'https://openrouter.ai/api/v1',
        'api_key' => 'sk-or-test',
    ]], 'json', 'ai');
}

test('the model id box refuses a provider name', function () {
    configureOpenRouter();

    $response = $this->actingAs(aiAdmin(), 'admin')
        ->from(route('admin.settings.ai.index'))
        ->post(route('admin.settings.ai.save'), [
            'models' => [
                ['name' => 'OpenRouter', 'provider' => 'OpenRouter'],
            ],
        ]);

    $response->assertSessionHasErrors('models.0.name');

    expect(app(SettingService::class)->get('ai.models', []))->toBe([]);
});

test('an agent cannot be pointed at a provider name as its model', function () {
    configureOpenRouter();

    $response = $this->actingAs(aiAdmin(), 'admin')
        ->from(route('admin.settings.ai.index'))
        ->post(route('admin.settings.ai.save'), [
            'agents' => [
                ['name' => 'Product Description Agent', 'provider' => 'OpenRouter', 'model' => 'OpenRouter'],
            ],
        ]);

    $response->assertSessionHasErrors('agents.0.model');
});

test('a real model id still saves', function () {
    configureOpenRouter();

    $response = $this->actingAs(aiAdmin(), 'admin')
        ->from(route('admin.settings.ai.index'))
        ->post(route('admin.settings.ai.save'), [
            'models' => [
                ['name' => 'openrouter/free', 'provider' => 'OpenRouter'],
            ],
        ]);

    $response->assertSessionHasNoErrors();

    expect(app(SettingService::class)->get('ai.models', [])[0]['name'])->toBe('openrouter/free');
});

test('a refusal from the provider is reported in words, not raw json', function () {
    configureOpenRouter();

    $settings = app(SettingService::class);
    $settings->set('ai.models', [['name' => 'OpenRouter', 'provider' => 'OpenRouter']], 'json', 'ai');
    $settings->set('ai.default_provider', 'OpenRouter', 'string', 'ai');

    Http::fake([
        '*' => Http::response([
            'error' => ['message' => 'OpenRouter is not a valid model ID', 'code' => 400],
        ], 400),
    ]);

    $product = Product::create([
        'name' => 'AI test product',
        'price' => 100,
        'quantity' => 1,
        'status' => 'active',
        'type' => 'simple',
    ]);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    expect($message)
        ->toContain('The AI provider refused the request: OpenRouter is not a valid model ID')
        ->toContain('Settings → AI → Models')
        ->toContain('openrouter/free')
        ->not->toContain('{"error"');
});

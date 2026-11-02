<?php

declare(strict_types=1);

/**
 * What the AI sends back, and what the store does with it.
 *
 * A free model that replies with nothing used to crash the request with a PHP
 * type error ("must be of type string, null returned"), which told the admin
 * nothing. And the whole feature only ever asked for English, on a shop whose
 * storefront is in Dari and Pashto.
 */

use App\Models\User;
use Cartxis\Core\Services\SettingService;
use Cartxis\Product\Models\Product;
use Cartxis\Product\Services\AiProductDescriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

function aiReady(): Product
{
    $settings = app(SettingService::class);
    $settings->set('ai.enabled', true, 'boolean', 'ai');
    $settings->set('ai.providers', [[
        'name' => 'OpenRouter',
        'type' => 'custom',
        'base_url' => 'https://openrouter.ai/api/v1',
        'api_key' => 'sk-or-test',
    ]], 'json', 'ai');
    $settings->set('ai.models', [['name' => 'openrouter/free', 'provider' => 'OpenRouter']], 'json', 'ai');
    $settings->set('ai.default_provider', 'OpenRouter', 'string', 'ai');

    return Product::create([
        'name' => 'Test kettle',
        'price' => 100,
        'quantity' => 1,
        'status' => 'active',
        'type' => 'simple',
    ]);
}

function aiReplies(mixed $message): void
{
    Http::fake(['*' => Http::response(['choices' => [['message' => $message]]], 200)]);
}

function lastAiRequestBody(): array
{
    $sent = [];
    Http::recorded(function ($request) use (&$sent) {
        $sent = $request->data();
    });

    return $sent;
}

test('an empty reply is explained instead of crashing', function () {
    $product = aiReady();
    aiReplies(['content' => null]);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    expect($message)
        ->toContain('The AI answered with nothing at all')
        ->toContain('Max tokens')
        ->not->toContain('must be of type string');
});

test('a reply split into parts is still read', function () {
    $product = aiReady();
    aiReplies(['content' => [
        ['text' => '{"short_description":"Half one, '],
        ['text' => 'half two."}'],
    ]]);

    $result = app(AiProductDescriptionService::class)->generate($product);

    expect($result['data']['short_description'])->toBe('Half one, half two.');
});

test('a model that only fills the reasoning field is still read', function () {
    $product = aiReady();
    aiReplies(['content' => '', 'reasoning' => '{"short_description":"From reasoning."}']);

    $result = app(AiProductDescriptionService::class)->generate($product);

    expect($result['data']['short_description'])->toBe('From reasoning.');
});

test('an error sent back with a 200 is reported as a refusal', function () {
    $product = aiReady();
    Http::fake(['*' => Http::response(['error' => ['message' => 'Rate limited, try later']], 200)]);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    expect($message)->toContain('Rate limited, try later');
});

test('Dari is named for the model, not sent as a bare code', function () {
    $product = aiReady();
    aiReplies(['content' => '{"short_description":"ok"}']);

    app(AiProductDescriptionService::class)->generate($product, ['language' => 'fa']);

    $prompt = json_encode(lastAiRequestBody(), JSON_UNESCAPED_UNICODE);

    expect($prompt)
        ->toContain('Dari (Afghan Persian)')
        ->toContain('Do not answer in English');
});

test('Pashto is named for the model', function () {
    $product = aiReady();
    aiReplies(['content' => '{"short_description":"ok"}']);

    app(AiProductDescriptionService::class)->generate($product, ['language' => 'ps']);

    expect(json_encode(lastAiRequestBody(), JSON_UNESCAPED_UNICODE))->toContain('Pashto');
});

test('with no language asked for, the dashboard language is used', function () {
    $product = aiReady();
    aiReplies(['content' => '{"short_description":"ok"}']);

    app()->setLocale('ps');
    app(AiProductDescriptionService::class)->generate($product);

    expect(json_encode(lastAiRequestBody(), JSON_UNESCAPED_UNICODE))->toContain('Pashto');
});

test('the product page accepts Dari and Pashto and refuses a language it cannot write', function () {
    $product = aiReady();
    aiReplies(['content' => '{"short_description":"ok"}']);

    $admin = User::factory()->withoutTwoFactor()->create([
        'role' => 'admin',
        'is_active' => true,
    ]);

    foreach (['fa', 'ps'] as $language) {
        $this->actingAs($admin, 'admin')
            ->postJson("/admin/catalog/products/{$product->id}/generate-description", ['language' => $language])
            ->assertOk();
    }

    $this->actingAs($admin, 'admin')
        ->postJson("/admin/catalog/products/{$product->id}/generate-description", ['language' => 'klingon'])
        ->assertStatus(422);
});

test('a price written in Eastern digits is still read as a price', function () {
    aiReady();

    Http::fake(['*' => Http::response(['choices' => [['message' => ['content' => json_encode([
        'price_options' => [
            ['variation' => 'undercut', 'source_label' => 'بازار', 'price' => '۹۵۰', 'details' => 'ارزان'],
            ['variation' => 'competitive', 'source_label' => 'بازار', 'price' => '۱٬۰۵۰', 'details' => 'معمولی'],
            ['variation' => 'balanced', 'source_label' => 'بازار', 'price' => '۱۱۰۰', 'details' => 'متوسط'],
            ['variation' => 'premium', 'source_label' => 'بازار', 'price' => '۱۲۵۰', 'details' => 'بالا'],
        ],
    ], JSON_UNESCAPED_UNICODE)]]]], 200)]);

    $result = app(AiProductDescriptionService::class)->generatePriceComparison([
        'product_name' => 'Kettle',
        'category' => 'Kitchen',
        'current_price' => 1000,
    ]);

    expect($result['options'])->toHaveCount(4)
        ->and($result['options'][0]['price'])->toBe(950.0);
});

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

test('JSON wrapped in a markdown fence is read', function () {
    $product = aiReady();
    aiReplies(['content' => "```json\n{\"short_description\":\"Fenced.\"}\n```"]);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Fenced.');
});

test('JSON with a sentence in front of it is read', function () {
    $product = aiReady();
    aiReplies(['content' => "Sure! Here is the JSON you asked for:\n{\"short_description\":\"Padded.\"}\nHope that helps."]);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Padded.');
});

test('a trailing comma does not throw the whole reply away', function () {
    $product = aiReady();
    aiReplies(['content' => '{"short_description":"Comma.","keywords":["a","b",],}']);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Comma.');
});

test('curly quotes are straightened before parsing', function () {
    $product = aiReady();
    aiReplies(['content' => '{“short_description”:“Curly.”}']);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Curly.');
});

test('prose containing braces does not defeat the parser', function () {
    $product = aiReady();
    aiReplies(['content' => 'Note: use {product} placeholders. {"short_description":"Real one."}']);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Real one.');
});

test('a reply cut off by the token limit says so, and says what to raise', function () {
    $product = aiReady();

    Http::fake(['*' => Http::response([
        'choices' => [[
            'finish_reason' => 'length',
            'message' => ['content' => '{"short_description":"It starts fine but then'],
        ]],
    ], 200)]);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    expect($message)
        ->toContain('cut off halfway')
        ->toContain('Max tokens')
        ->not->toContain('not following the agent prompt');
});

test('a reply that is simply not JSON blames the prompt, not the token limit', function () {
    $product = aiReady();
    aiReplies(['content' => 'I am afraid I cannot help with that request.']);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    expect($message)->toContain('format this page cannot read');
});

test('a cut-off reply is retried with more room, without anyone changing a setting', function () {
    $product = aiReady();

    Http::fakeSequence()
        ->push(['choices' => [['finish_reason' => 'length', 'message' => ['content' => '{"short_description":"cut']]]], 200)
        ->push(['choices' => [['finish_reason' => 'stop', 'message' => ['content' => '{"short_description":"Second time lucky."}']]]], 200);

    $result = app(AiProductDescriptionService::class)->generate($product);

    expect($result['data']['short_description'])->toBe('Second time lucky.');

    $asked = [];
    Http::recorded(function ($request) use (&$asked) {
        $asked[] = $request->data()['max_tokens'];
    });

    expect($asked)->toHaveCount(2)
        ->and($asked[1])->toBeGreaterThan($asked[0]);
});

test('an empty reply is retried before anyone is told about it', function () {
    $product = aiReady();

    Http::fakeSequence()
        ->push(['choices' => [['message' => ['content' => null]]]], 200)
        ->push(['choices' => [['message' => ['content' => '{"short_description":"Here on the retry."}']]]], 200);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Here on the retry.');
});

test('a busy free model is waited out', function () {
    $product = aiReady();

    Http::fakeSequence()
        ->push(['error' => ['message' => 'Rate limited, please try again shortly']], 429)
        ->push(['choices' => [['message' => ['content' => '{"short_description":"Served after the wait."}']]]], 200);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Served after the wait.');
});

test('an unreadable reply is retried too, since models vary', function () {
    $product = aiReady();

    Http::fakeSequence()
        ->push(['choices' => [['message' => ['content' => 'Sorry, I would rather chat.']]]], 200)
        ->push(['choices' => [['message' => ['content' => '{"short_description":"Proper JSON this time."}']]]], 200);

    expect(app(AiProductDescriptionService::class)->generate($product)['data']['short_description'])
        ->toBe('Proper JSON this time.');
});

test('a wrong model id is not retried, because asking again cannot help', function () {
    $product = aiReady();

    Http::fake(['*' => Http::response(['error' => ['message' => 'OpenRouter is not a valid model ID']], 400)]);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    $calls = 0;
    Http::recorded(function () use (&$calls) {
        $calls++;
    });

    expect($message)->toContain('is not a valid model ID')
        ->and($calls)->toBe(1);
});

test('it gives up after three tries and says what went wrong', function () {
    $product = aiReady();
    aiReplies(['content' => 'Still not JSON.']);

    $message = null;

    try {
        app(AiProductDescriptionService::class)->generate($product);
    } catch (RuntimeException $e) {
        $message = $e->getMessage();
    }

    $calls = 0;
    Http::recorded(function () use (&$calls) {
        $calls++;
    });

    expect($calls)->toBe(3)
        ->and($message)->toContain('format this page cannot read');
});

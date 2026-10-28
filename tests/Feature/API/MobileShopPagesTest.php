<?php

use Cartxis\CMS\Models\Page;

/*
|--------------------------------------------------------------------------
| The shop's own pages, shared by the website and the app
|--------------------------------------------------------------------------
|
| About us, the privacy policy and the terms are written once in the
| dashboard. The website has always read them from there; the app used to
| carry its own copy in its code, so the two said different things and only
| one could be corrected.
|
| These tests hold the endpoint the app reads to the same source, and keep it
| reachable without an account — a shopper reads the privacy policy before
| deciding to trust the shop, and the app stores require it.
|
*/

function publishedPage(array $overrides = []): Page
{
    return Page::create(array_merge([
        'title' => 'Privacy Policy',
        'url_key' => 'privacy-policy',
        'content' => '<h2>Your data</h2><p>We keep your order details.</p>',
        'status' => 'published',
    ], $overrides));
}

it('serves the page the dashboard holds, without needing an account', function () {
    publishedPage();

    $response = $this->getJson('/api/v1/pages/privacy-policy')->assertOk();

    expect($response->json('data.title'))->toBe('Privacy Policy')
        ->and($response->json('data.slug'))->toBe('privacy-policy')
        // The HTML is passed through for the app to render, not stripped.
        ->and($response->json('data.content'))->toContain('<h2>Your data</h2>');
});

it('shows an edit made in the dashboard', function () {
    $page = publishedPage();

    $page->update(['content' => '<p>We changed our minds.</p>']);

    expect($this->getJson('/api/v1/pages/privacy-policy')->json('data.content'))
        ->toContain('We changed our minds');
});

it('does not serve a page the shop has not published', function () {
    publishedPage(['status' => 'draft']);

    $this->getJson('/api/v1/pages/privacy-policy')
        ->assertStatus(404)
        ->assertJsonPath('error_code', 'PAGE_NOT_FOUND');
});

it('says so plainly when there is no such page', function () {
    $this->getJson('/api/v1/pages/nothing-here')
        ->assertStatus(404)
        ->assertJsonPath('error_code', 'PAGE_NOT_FOUND');
});

it('serves the other pages the app links to', function () {
    publishedPage(['title' => 'About Us', 'url_key' => 'about-us']);
    publishedPage([
        'title' => 'Terms & Conditions',
        'url_key' => 'terms-and-conditions',
    ]);

    expect($this->getJson('/api/v1/pages/about-us')->json('data.title'))
        ->toBe('About Us')
        ->and($this->getJson('/api/v1/pages/terms-and-conditions')->json('data.title'))
        ->toBe('Terms & Conditions');
});

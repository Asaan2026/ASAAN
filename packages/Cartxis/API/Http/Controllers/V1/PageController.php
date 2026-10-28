<?php

namespace Cartxis\API\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use Cartxis\API\Helpers\ApiResponse;
use Cartxis\CMS\Models\Page;
use Illuminate\Http\JsonResponse;

/**
 * The shop's own pages — About us, Privacy policy, Terms — as the dashboard
 * holds them.
 *
 * The website has always served these from Dashboard > CMS > Pages, while the
 * phone app carried its own copy written into the code, which nobody could
 * edit and which said something different. This endpoint is what lets the app
 * show the same words the website shows, so editing the page once changes it
 * everywhere.
 *
 * Public on purpose: these are the pages a shopper reads before deciding to
 * trust the shop, and app stores require the privacy policy to be reachable
 * without an account.
 */
class PageController extends Controller
{
    public function show(string $slug): JsonResponse
    {
        $page = Page::query()
            ->where('url_key', $slug)
            ->where('status', 'published')
            ->first();

        if (! $page) {
            return ApiResponse::notFound('Page not found', 'PAGE_NOT_FOUND');
        }

        return ApiResponse::success([
            'title' => $page->title,
            'slug' => $page->url_key,
            // HTML, as written in the dashboard's editor. The app renders it
            // rather than printing the tags.
            'content' => (string) $page->content,
            'updated_at' => $page->updated_at?->toIso8601String(),
        ], 'Page retrieved successfully');
    }
}

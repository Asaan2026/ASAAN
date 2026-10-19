<?php

namespace Cartxis\Shop\Http\Controllers\Account;

use Cartxis\API\Models\CustomerNotification;
use Cartxis\Core\Services\ThemeViewResolver;
use Cartxis\Shop\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The customer's own notifications, for the website bell and Notifications page.
 *
 * The API has an equivalent controller, but its routes require a Sanctum token
 * and the website logs in with a session -- so a separate controller on the
 * `web` guard is needed rather than reusing the token-only routes.
 *
 * Every query is scoped to the signed-in user, so one customer can never read or
 * mark another customer's notifications, even by guessing an id.
 */
class NotificationController extends Controller
{
    protected ThemeViewResolver $themeResolver;

    public function __construct(ThemeViewResolver $themeResolver)
    {
        $this->themeResolver = $themeResolver;
    }

    /**
     * The Notifications page for a signed-in customer.
     */
    public function index(Request $request)
    {
        $notifications = $this->queryFor($request)
            ->paginate(20)
            ->through(fn ($notification) => $this->toArray($notification));

        return $this->themeResolver->inertia('Account/Notifications/Index', [
            'notifications' => $notifications,
        ]);
    }

    /**
     * The bell's data: the newest few notifications and the unread count. Polled
     * by the header bell, mirroring the admin bell's `/admin/notifications`.
     */
    public function feed(Request $request): JsonResponse
    {
        $limit = max(1, min((int) $request->integer('limit', 10), 30));

        $notifications = $this->queryFor($request)
            ->limit($limit)
            ->get()
            ->map(fn ($notification) => $this->toArray($notification));

        return response()->json([
            'notifications' => $notifications,
            'unread_count' => $this->unreadQueryFor($request)->count(),
        ]);
    }

    /**
     * Just the number on the bell, for the silent poll.
     */
    public function unreadCount(Request $request): JsonResponse
    {
        return response()->json([
            'unread_count' => $this->unreadQueryFor($request)->count(),
        ]);
    }

    /**
     * Mark one notification as read. Scoped to the user, so a wrong id is a 404,
     * never somebody else's notification.
     */
    public function markRead(Request $request, int $id): JsonResponse
    {
        $notification = $this->queryFor($request)->find($id);

        if (! $notification) {
            return response()->json([
                'message' => 'That notification was not found.',
            ], 404);
        }

        $notification->markAsRead();

        return response()->json([
            'success' => true,
            'notification' => $this->toArray($notification->fresh()),
            'unread_count' => $this->unreadQueryFor($request)->count(),
        ]);
    }

    /**
     * Mark every unread notification as read, for the "mark all" tap.
     */
    public function markAllRead(Request $request): JsonResponse
    {
        $this->unreadQueryFor($request)->update(['read_at' => now()]);

        return response()->json([
            'success' => true,
            'unread_count' => 0,
        ]);
    }

    /**
     * The base query: this user's notifications, newest first.
     */
    protected function queryFor(Request $request)
    {
        return CustomerNotification::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->orderByDesc('id');
    }

    /**
     * Only this user's unread notifications.
     */
    protected function unreadQueryFor(Request $request)
    {
        return $this->queryFor($request)->whereNull('read_at');
    }

    /**
     * One notification as the front end reads it. Kept in step with the API
     * resource so the app and the website show the same fields.
     *
     * @return array<string, mixed>
     */
    protected function toArray($notification): array
    {
        return [
            'id' => $notification->id,
            'type' => $notification->type,
            'title' => $notification->title,
            'body' => $notification->body,
            'data' => $notification->data ?? [],
            'read' => $notification->read_at !== null,
            'read_at' => $notification->read_at?->toIso8601String(),
            'created_at' => $notification->created_at?->toIso8601String(),
            'created_at_human' => $notification->created_at?->diffForHumans(),
        ];
    }
}

<?php

namespace Cartxis\API\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use Cartxis\API\Helpers\ApiResponse;
use Cartxis\API\Http\Resources\CustomerNotificationResource;
use Cartxis\API\Models\CustomerNotification;
use Cartxis\API\Models\DeviceToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * The customer's own notifications, for the app's bell and Notifications screen.
 *
 * Every query is scoped to the signed-in user, so one customer can never read or
 * mark another customer's notifications, even by guessing an id.
 */
class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $query = CustomerNotification::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->orderByDesc('id');

        if ($request->boolean('unread_only')) {
            $query->unread();
        }

        $paginator = $query->paginate($perPage);

        $paginator->getCollection()->transform(
            fn (CustomerNotification $notification) => (new CustomerNotificationResource($notification))->resolve()
        );

        return ApiResponse::paginated($paginator, 'Notifications retrieved successfully');
    }

    /**
     * The number on the bell.
     */
    public function unreadCount(Request $request)
    {
        $count = CustomerNotification::where('user_id', $request->user()->id)
            ->unread()
            ->count();

        return ApiResponse::success(['unread_count' => $count]);
    }

    /**
     * Mark one notification as read. Scoped to the user, so a wrong id is a 404,
     * never somebody else's notification.
     */
    public function markRead(Request $request, int $id)
    {
        $notification = CustomerNotification::where('user_id', $request->user()->id)
            ->find($id);

        if (! $notification) {
            return ApiResponse::notFound('That notification was not found.', 'NOTIFICATION_NOT_FOUND');
        }

        $notification->markAsRead();

        return ApiResponse::success(
            (new CustomerNotificationResource($notification))->resolve(),
            'Notification marked as read.'
        );
    }

    /**
     * Mark every unread notification as read, for the "mark all" tap.
     */
    public function markAllRead(Request $request)
    {
        $updated = CustomerNotification::where('user_id', $request->user()->id)
            ->unread()
            ->update(['read_at' => now()]);

        return ApiResponse::success(['marked_read' => $updated], 'All notifications marked as read.');
    }

    /**
     * Remember the phone's push token so the server can reach it later.
     *
     * Upserted on the token: the same phone signing in as someone else moves the
     * row to that account instead of leaving a second copy pointing at the old
     * one, which would push one person's order to another person's phone.
     */
    public function registerDevice(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', 'string', 'in:android,ios,web'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator);
        }

        $device = DeviceToken::updateOrCreate(
            ['token' => $request->input('token')],
            [
                'user_id' => $request->user()->id,
                'platform' => $request->input('platform', 'android'),
                'last_seen_at' => now(),
            ]
        );

        return ApiResponse::success([
            'id' => $device->id,
            'platform' => $device->platform,
        ], 'Device registered for notifications.');
    }

    /**
     * Forget a phone, for example when the customer signs out.
     */
    public function unregisterDevice(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'token' => ['required', 'string', 'max:512'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator);
        }

        DeviceToken::where('user_id', $request->user()->id)
            ->where('token', $request->input('token'))
            ->delete();

        return ApiResponse::success(null, 'Device removed.');
    }
}

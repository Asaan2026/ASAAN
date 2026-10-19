<?php

namespace Cartxis\API\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use Cartxis\Admin\Services\AdminNotificationService;
use Cartxis\API\Helpers\ApiResponse;
use Cartxis\Core\Services\SettingService;
use Cartxis\Marketing\Models\ContactMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

/**
 * Public storefront contact details and the contact form.
 *
 * Both are deliberately unauthenticated: the phone/WhatsApp/email details and
 * the "send us a message" form have to work for a shopper who has not signed
 * in. The lookup is a handful of settings rows, and the write is rate-limited
 * so the form cannot be used to flood the inbox.
 */
class StorefrontController extends Controller
{
    public function __construct(
        protected SettingService $settingService,
        protected AdminNotificationService $adminNotifications,
    ) {}

    /**
     * The shop's public contact details and app links.
     *
     * Read by the mobile app and by any front end that needs them. The values
     * live in the dashboard, so changing the number there takes effect without
     * a new app release.
     */
    public function contact(): JsonResponse
    {
        return ApiResponse::success($this->contactData(), 'Contact details retrieved successfully');
    }

    /**
     * Save a message from the website / app contact form.
     */
    public function submitMessage(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|max:255',
            'phone' => 'nullable|string|max:50',
            'subject' => 'nullable|string|max:255',
            'message' => 'required|string|min:5|max:5000',
        ]);

        // An email or a phone number is needed, otherwise the message cannot be
        // answered and it is just noise in the inbox.
        if (blank($validated['email'] ?? null) && blank($validated['phone'] ?? null)) {
            throw ValidationException::withMessages([
                'email' => __('Please leave either an email address or a phone number so we can reply.'),
            ]);
        }

        $message = ContactMessage::create([
            'name' => $validated['name'],
            'email' => $validated['email'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'subject' => $validated['subject'] ?? null,
            'message' => $validated['message'],
            'status' => ContactMessage::STATUS_NEW,
            'ip_address' => $request->ip(),
        ]);

        // The owner hears about the message through the admin bell, the same
        // way they hear about new orders. A failure here must never stop the
        // shopper's message from being saved.
        try {
            $this->adminNotifications->notifyAllAdmins(
                type: 'contact.message_received',
                title: 'New contact message',
                message: sprintf(
                    '%s wrote: %s',
                    $message->name,
                    mb_strimwidth($message->message, 0, 120, '…'),
                ),
                actionUrl: '/admin/marketing/messages/'.$message->id,
                entityType: 'contact_message',
                entityId: $message->id,
                severity: 'info',
            );
        } catch (\Throwable $e) {
            Log::error('Failed to create admin notification for contact message', [
                'contact_message_id' => $message->id,
                'error' => $e->getMessage(),
            ]);
        }

        return ApiResponse::success(
            ['id' => $message->id],
            __('Thank you — your message has been received. We will get back to you soon.'),
            201
        );
    }

    /**
     * The contact details in one place, read from the dashboard settings.
     *
     * @return array<string, mixed>
     */
    protected function contactData(): array
    {
        return [
            'whatsapp' => (string) $this->settingService->get('store_whatsapp', ''),
            'whatsapp_enabled' => (bool) $this->settingService->get('whatsapp_enabled', true),
            'whatsapp_message' => (string) $this->settingService->get('whatsapp_message', 'Hello Asaan Store, '),
            'phone' => (string) $this->settingService->get('store_phone', ''),
            'email' => (string) $this->settingService->get('store_email', ''),
            'play_store_url' => (string) $this->settingService->get('play_store_url', ''),
            'app_store_url' => (string) $this->settingService->get('app_store_url', ''),
        ];
    }
}

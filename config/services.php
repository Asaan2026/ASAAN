<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase Cloud Messaging (push notifications for the mobile app)
    |--------------------------------------------------------------------------
    |
    | The project id and the service-account JSON (downloaded once from the
    | Firebase console) are all that is needed to send a push over FCM's HTTP v1
    | API. When the path below is empty the app still gets in-app notifications;
    | only the push to the phone is skipped. Nothing else has to change to turn
    | push on later -- drop the file in place and set the two values.
    |
    */

    'fcm' => [
        'project_id' => env('FCM_PROJECT_ID'),
        'credentials' => env('FCM_CREDENTIALS_PATH'),
        // Empty by default: let Firebase use its own Android notification
        // channel, so push works without one being created on the phone first.
        'notification_channel' => env('FCM_ANDROID_CHANNEL', ''),
    ],

];

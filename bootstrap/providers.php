<?php

use App\Providers\AppServiceProvider;
use App\Providers\FortifyServiceProvider;
use Cartxis\Admin\Providers\AdminServiceProvider;
use Cartxis\API\Providers\APIServiceProvider;
use Cartxis\Blog\Providers\BlogServiceProvider;
use Cartxis\Calendar\CalendarServiceProvider;
use Cartxis\Cart\Providers\CartServiceProvider;
use Cartxis\CMS\Providers\CMSServiceProvider;
use Cartxis\Core\Providers\CoreServiceProvider;
use Cartxis\Core\Providers\MailConfigServiceProvider;
use Cartxis\Core\Providers\ThemeServiceProvider;
use Cartxis\Customer\Providers\CustomerServiceProvider;
use Cartxis\HesabPay\Providers\HesabPayServiceProvider;
use Cartxis\Identity\IdentityServiceProvider;
use Cartxis\Marketing\MarketingServiceProvider;
use Cartxis\PhonePe\Providers\PhonePeServiceProvider;
use Cartxis\Product\Providers\ProductServiceProvider;
use Cartxis\Razorpay\Providers\RazorpayServiceProvider;
use Cartxis\Referral\ReferralServiceProvider;
use Cartxis\Reports\ReportsServiceProvider;
use Cartxis\Sales\Providers\SalesServiceProvider;
use Cartxis\Service\ServiceServiceProvider;
use Cartxis\Settings\Providers\SettingsServiceProvider;
use Cartxis\Setup\Providers\SetupServiceProvider;
use Cartxis\Shop\Providers\ShopServiceProvider;
use Cartxis\Stripe\Providers\StripeServiceProvider;
use Cartxis\System\Providers\SystemServiceProvider;
use Cartxis\UIEditor\Providers\UIEditorServiceProvider;

return [
    AppServiceProvider::class,
    FortifyServiceProvider::class,
    ThemeServiceProvider::class,
    CoreServiceProvider::class,
    MailConfigServiceProvider::class,
    AdminServiceProvider::class,
    ProductServiceProvider::class,
    CartServiceProvider::class,
    ShopServiceProvider::class,
    SettingsServiceProvider::class,
    StripeServiceProvider::class,
    RazorpayServiceProvider::class,
    HesabPayServiceProvider::class,
    PhonePeServiceProvider::class,
    SalesServiceProvider::class,
    CustomerServiceProvider::class,
    SetupServiceProvider::class,  // Must be before CMS to prevent catch-all route conflict
    ServiceServiceProvider::class,  // Must be before CMS for the same reason: /services would be swallowed
    BlogServiceProvider::class,
    CMSServiceProvider::class,
    UIEditorServiceProvider::class,
    SystemServiceProvider::class,
    ReportsServiceProvider::class,
    MarketingServiceProvider::class,
    ReferralServiceProvider::class,
    IdentityServiceProvider::class,
    CalendarServiceProvider::class,
    APIServiceProvider::class,
];

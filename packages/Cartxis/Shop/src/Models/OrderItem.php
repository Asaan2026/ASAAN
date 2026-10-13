<?php

namespace Cartxis\Shop\Models;

use Cartxis\Core\Support\DisplayCurrency;
use Cartxis\Product\Models\Product;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'order_items';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<string>
     */
    protected $fillable = [
        'order_id',
        'product_id',
        'product_sku',
        'product_name',
        'product_image',
        'quantity',
        'price',
        'total',
        'tax_amount',
        'discount_amount',
        'options',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'quantity' => 'integer',
        'price' => 'decimal:2',
        'total' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'options' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the order that owns the order item.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Get the product associated with the order item.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Get the formatted price.
     */
    public function getFormattedPriceAttribute(): string
    {
        return DisplayCurrency::format((float) $this->price);
    }

    /**
     * Get the formatted total.
     */
    public function getFormattedTotalAttribute(): string
    {
        return DisplayCurrency::format((float) $this->total);
    }

    /**
     * Calculate the subtotal (quantity * price).
     */
    public function calculateSubtotal(): float
    {
        return $this->quantity * $this->price;
    }

    /**
     * Calculate the total including tax and discount.
     */
    public function calculateTotal(): float
    {
        $subtotal = $this->calculateSubtotal();

        return $subtotal + $this->tax_amount - $this->discount_amount;
    }

    /**
     * Check if the product is still available.
     */
    public function isProductAvailable(): bool
    {
        if (! $this->product) {
            return false;
        }

        return $this->product->status === 1 && $this->product->quantity >= $this->quantity;
    }

    /**
     * Get the product URL.
     */
    public function getProductUrlAttribute(): ?string
    {
        if (! $this->product) {
            return null;
        }

        return route('shop.products.show', ['slug' => $this->product->slug]);
    }

    /**
     * Get the product thumbnail URL.
     */
    public function getProductThumbnailAttribute(): ?string
    {
        if ($this->product_image) {
            return $this->product_image;
        }

        if ($this->product && $this->product->mainImage) {
            return $this->product->mainImage->url;
        }

        return asset('images/placeholder.png');
    }

    /**
     * Scope a query to only include items for a specific order.
     *
     * @param  Builder  $query
     * @return Builder
     */
    public function scopeForOrder($query, int $orderId)
    {
        return $query->where('order_id', $orderId);
    }

    /**
     * Scope a query to only include items for a specific product.
     *
     * @param  Builder  $query
     * @return Builder
     */
    public function scopeForProduct($query, int $productId)
    {
        return $query->where('product_id', $productId);
    }
}

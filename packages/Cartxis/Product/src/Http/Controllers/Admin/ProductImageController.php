<?php

namespace Cartxis\Product\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Cartxis\Product\Models\Product;
use Cartxis\Product\Models\ProductImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductImageController extends Controller
{
    /**
     * Upload product images
     */
    public function upload(Request $request, Product $product)
    {
        $request->validate([
            'images' => 'required|array',
            'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120', // 5MB max
        ]);

        $uploadedImages = [];

        foreach ($request->file('images') as $index => $image) {
            // Generate unique filename
            $filename = Str::uuid().'.'.$image->getClientOriginalExtension();

            // Define paths
            $path = 'products/'.$product->id;
            $fullPath = $path.'/'.$filename;

            // Store original image using the 'public' disk
            $storedPath = $image->storeAs($path, $filename, 'public');

            // Verify file was stored
            if (! $storedPath || ! Storage::disk('public')->exists($fullPath)) {
                continue; // Skip this image if storage failed
            }

            // Get the last position for ordering
            $lastPosition = $product->images()->max('position') ?? 0;

            // Create database record
            $productImage = $product->images()->create([
                'path' => $fullPath,
                'thumbnail_path' => $fullPath, // Using same path for now, can add thumbnail generation later
                'position' => $lastPosition + $index + 1,
                'alt_text' => $product->name,
            ]);

            // The first image uploaded for a product becomes its main image
            // automatically, so the storefront and the admin list preview show
            // it without an extra "set as main" click. Previously main_image_id
            // stayed null until someone clicked set-main, which is why a freshly
            // uploaded image was invisible in the storefront and the admin list.
            if (! $product->main_image_id) {
                $product->update(['main_image_id' => $productImage->id]);
            }

            // Return with full URL
            $productImage->url = Storage::disk('public')->url($fullPath);

            $uploadedImages[] = $productImage;
        }

        // Drop the cached product so the new image shows up immediately
        // instead of after the cache TTL (1 hour).
        cache()->forget('shop.product.'.$product->slug);
        cache()->forget('shop.related_products.'.$product->id.'.4');

        return response()->json([
            'message' => 'Images uploaded successfully',
            'images' => $uploadedImages,
        ]);
    }

    /**
     * Delete a product image
     */
    public function destroy(Product $product, ProductImage $image)
    {
        // Verify the image belongs to this product
        if ($image->product_id !== $product->id) {
            return response()->json([
                'message' => 'Image not found for this product',
            ], 404);
        }

        // Delete files from storage
        Storage::disk('public')->delete($image->path);
        if ($image->thumbnail_path && $image->thumbnail_path !== $image->path) {
            Storage::disk('public')->delete($image->thumbnail_path);
        }

        // If the deleted image was the main one, promote the next available
        // image (or clear it) so the preview never points at a missing file.
        if ($product->main_image_id === $image->id) {
            $next = $product->images()->where('id', '!=', $image->id)->orderBy('position')->first();
            $product->update(['main_image_id' => $next?->id]);
        }

        // Delete database record
        $image->delete();

        // Reorder remaining images
        $product->images()->orderBy('position')->get()->each(function ($img, $index) {
            $img->update(['position' => $index + 1]);
        });

        cache()->forget('shop.product.'.$product->slug);
        cache()->forget('shop.related_products.'.$product->id.'.4');

        return response()->json([
            'message' => 'Image deleted successfully',
        ]);
    }

    /**
     * Reorder product images
     */
    public function reorder(Request $request, Product $product)
    {
        $request->validate([
            'image_ids' => 'required|array',
            'image_ids.*' => 'exists:product_images,id',
        ]);

        $imageIds = $request->input('image_ids');

        // Update positions
        foreach ($imageIds as $index => $imageId) {
            ProductImage::where('id', $imageId)
                ->where('product_id', $product->id)
                ->update(['position' => $index + 1]);
        }

        return response()->json([
            'message' => 'Images reordered successfully',
        ]);
    }

    /**
     * Set main image for product
     */
    public function setMain(Request $request, Product $product, ProductImage $image)
    {
        // Verify the image belongs to this product
        if ($image->product_id !== $product->id) {
            return response()->json([
                'message' => 'Image not found for this product',
            ], 404);
        }

        // Update product's main_image_id
        $product->update(['main_image_id' => $image->id]);

        cache()->forget('shop.product.'.$product->slug);

        return response()->json([
            'message' => 'Main image updated successfully',
            'main_image_id' => $image->id,
        ]);
    }

    /**
     * Update image details (alt text, etc.)
     */
    public function update(Request $request, Product $product, ProductImage $image)
    {
        // Verify the image belongs to this product
        if ($image->product_id !== $product->id) {
            return response()->json([
                'message' => 'Image not found for this product',
            ], 404);
        }

        $validated = $request->validate([
            'alt_text' => 'nullable|string|max:255',
        ]);

        $image->update($validated);

        return response()->json([
            'message' => 'Image updated successfully',
            'image' => $image,
        ]);
    }
}

<?php

namespace Cartxis\API\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One customer notification as the app reads it.
 *
 * "read" is derived from read_at so the app never has to test a timestamp; the
 * list and the unread badge stay in step with the same value.
 */
class CustomerNotificationResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'title' => $this->title,
            'body' => $this->body,
            'data' => $this->data ?? [],
            'read' => $this->read_at !== null,
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}

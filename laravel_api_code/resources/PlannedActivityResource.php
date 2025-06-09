<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PlannedActivityResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'planningId' => $this->planning_id,
            'activityId' => $this->activity_id,
            'scheduledDate' => $this->scheduled_date,
            'scheduledTime' => $this->scheduled_time,
            'reminder' => $this->reminder,
            'completed' => $this->completed,
            'activity' => new ActivityResource($this->whenLoaded('activity')),
        ];
    }
} 
<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class FollowUpSuggestionResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'childId' => $this->child_id,
            'completedActivityId' => $this->completed_activity_id,
            'suggestedActivityId' => $this->suggested_activity_id,
            'autoAssigned' => $this->auto_assigned,
            'assignedDate' => $this->assigned_date,
            'child' => new ChildResource($this->whenLoaded('child')),
            'completedActivity' => new ActivityResource($this->whenLoaded('completedActivity')),
            'suggestedActivity' => new ActivityResource($this->whenLoaded('suggestedActivity')),
        ];
    }
} 
<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ChecklistItemResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'childId' => $this->child_id,
            'activityId' => $this->activity_id,
            'assignedDate' => $this->assigned_date,
            'dueDate' => $this->due_date,
            'status' => $this->status,
            'homeObservation' => $this->home_observation,
            'schoolObservation' => $this->school_observation,
            'customStepsUsed' => $this->custom_steps_used,
            'child' => new ChildResource($this->whenLoaded('child')),
            'activity' => new ActivityResource($this->whenLoaded('activity')),
        ];
    }
} 
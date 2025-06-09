<?php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CustomStepResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'activityId' => $this->activity_id,
            'teacherId' => $this->teacher_id,
            'steps' => $this->steps,
        ];
    }
} 
<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FollowUpSuggestion extends Model
{
    protected $fillable = [
        'child_id', 'completed_activity_id', 'suggested_activity_id', 'auto_assigned', 'assigned_date'
    ];
    protected $casts = [
        'auto_assigned' => 'boolean',
        'assigned_date' => 'datetime',
    ];
    public function child() { return $this->belongsTo(Child::class); }
    public function completedActivity() { return $this->belongsTo(Activity::class, 'completed_activity_id'); }
    public function suggestedActivity() { return $this->belongsTo(Activity::class, 'suggested_activity_id'); }
} 
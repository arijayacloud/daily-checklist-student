<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlannedActivity extends Model
{
    protected $fillable = [
        'planning_id', 'activity_id', 'scheduled_date', 'scheduled_time', 'reminder', 'completed'
    ];
    protected $casts = [
        'scheduled_date' => 'datetime',
        'reminder' => 'boolean',
        'completed' => 'boolean',
    ];
    public function planning() { return $this->belongsTo(Planning::class); }
    public function activity() { return $this->belongsTo(Activity::class); }
} 
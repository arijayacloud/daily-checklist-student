<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChecklistItem extends Model
{
    protected $casts = [
        'home_observation' => 'array',
        'school_observation' => 'array',
        'custom_steps_used' => 'array',
        'assigned_date' => 'datetime',
        'due_date' => 'datetime',
    ];
    protected $fillable = [
        'child_id', 'activity_id', 'assigned_date', 'due_date', 'status',
        'home_observation', 'school_observation', 'custom_steps_used',
    ];
    public function child() { return $this->belongsTo(Child::class); }
    public function activity() { return $this->belongsTo(Activity::class); }
} 
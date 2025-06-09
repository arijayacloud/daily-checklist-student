<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomStep extends Model
{
    protected $fillable = [
        'activity_id', 'teacher_id', 'steps'
    ];
    protected $casts = [
        'steps' => 'array',
    ];
    public function activity() { return $this->belongsTo(Activity::class); }
} 
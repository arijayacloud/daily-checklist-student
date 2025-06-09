<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checklist;
use App\Http\Resources\ChecklistResource;
use Illuminate\Http\Request;

class ChecklistController extends Controller
{
    public function index()
    {
        return ChecklistResource::collection(Checklist::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'is_checked' => 'boolean',
        ]);
        $checklist = Checklist::create($data);
        return new ChecklistResource($checklist);
    }

    public function show($id)
    {
        return new ChecklistResource(Checklist::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $checklist = Checklist::findOrFail($id);
        $data = $request->validate([
            'name' => 'string',
            'is_checked' => 'boolean',
        ]);
        $checklist->update($data);
        return new ChecklistResource($checklist);
    }

    public function destroy($id)
    {
        $checklist = Checklist::findOrFail($id);
        $checklist->delete();
        return response()->json(null, 204);
    }

    public function bulkAssign(Request $request)
    {
        $childIds = $request->input('child_ids');
        $activityId = $request->input('activity_id');
        $customStepsUsed = $request->input('custom_steps_used', []);
        $dueDate = $request->input('due_date');

        foreach ($childIds as $childId) {
            \App\Models\ChecklistItem::create([
                'child_id' => $childId,
                'activity_id' => $activityId,
                'assigned_date' => now(),
                'due_date' => $dueDate,
                'status' => 'pending',
                'home_observation' => json_encode(['completed' => false]),
                'school_observation' => json_encode(['completed' => false]),
                'custom_steps_used' => $customStepsUsed,
            ]);
        }
        return response()->json(['message' => 'Bulk assign success']);
    }

    public function followUp(Request $request)
    {
        $childId = $request->input('child_id');
        $completedActivityId = $request->input('completed_activity_id');
        $suggestedActivityId = $request->input('suggested_activity_id');
        $autoAssigned = $request->input('auto_assigned', false);
        $assignedDate = $request->input('assigned_date');

        $followUp = \App\Models\FollowUpSuggestion::create([
            'child_id' => $childId,
            'completed_activity_id' => $completedActivityId,
            'suggested_activity_id' => $suggestedActivityId,
            'auto_assigned' => $autoAssigned,
            'assigned_date' => $assignedDate,
        ]);
        return new \App\Http\Resources\FollowUpSuggestionResource($followUp);
    }
} 
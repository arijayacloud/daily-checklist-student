<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Http\Resources\ActivityResource;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    public function index()
    {
        return ActivityResource::collection(Activity::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'date' => 'required|date',
        ]);
        $activity = Activity::create($data);
        return new ActivityResource($activity);
    }

    public function show($id)
    {
        return new ActivityResource(Activity::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $activity = Activity::findOrFail($id);
        $data = $request->validate([
            'name' => 'string',
            'date' => 'date',
        ]);
        $activity->update($data);
        return new ActivityResource($activity);
    }

    public function destroy($id)
    {
        $activity = Activity::findOrFail($id);
        $activity->delete();
        return response()->json(null, 204);
    }
} 
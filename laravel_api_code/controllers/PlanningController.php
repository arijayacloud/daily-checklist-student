<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Planning;
use App\Http\Resources\PlanningResource;
use Illuminate\Http\Request;

class PlanningController extends Controller
{
    public function index()
    {
        return PlanningResource::collection(Planning::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string',
            'description' => 'nullable|string',
        ]);
        $planning = Planning::create($data);
        return new PlanningResource($planning);
    }

    public function show($id)
    {
        return new PlanningResource(Planning::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $planning = Planning::findOrFail($id);
        $data = $request->validate([
            'title' => 'string',
            'description' => 'nullable|string',
        ]);
        $planning->update($data);
        return new PlanningResource($planning);
    }

    public function destroy($id)
    {
        $planning = Planning::findOrFail($id);
        $planning->delete();
        return response()->json(null, 204);
    }
} 
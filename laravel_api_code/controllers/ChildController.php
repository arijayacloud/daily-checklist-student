<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Http\Resources\ChildResource;
use Illuminate\Http\Request;

class ChildController extends Controller
{
    public function index()
    {
        return ChildResource::collection(Child::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'age' => 'required|integer',
        ]);
        $child = Child::create($data);
        return new ChildResource($child);
    }

    public function show($id)
    {
        return new ChildResource(Child::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $child = Child::findOrFail($id);
        $data = $request->validate([
            'name' => 'string',
            'age' => 'integer',
        ]);
        $child->update($data);
        return new ChildResource($child);
    }

    public function destroy($id)
    {
        $child = Child::findOrFail($id);
        $child->delete();
        return response()->json(null, 204);
    }
} 
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Http\Resources\NotificationResource;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index()
    {
        return NotificationResource::collection(Notification::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'message' => 'required|string',
            'created_at' => 'nullable|date',
        ]);
        $notification = Notification::create($data);
        return new NotificationResource($notification);
    }

    public function show($id)
    {
        return new NotificationResource(Notification::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $notification = Notification::findOrFail($id);
        $data = $request->validate([
            'message' => 'string',
            'created_at' => 'nullable|date',
        ]);
        $notification->update($data);
        return new NotificationResource($notification);
    }

    public function destroy($id)
    {
        $notification = Notification::findOrFail($id);
        $notification->delete();
        return response()->json(null, 204);
    }
} 
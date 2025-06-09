<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ChecklistController;
use App\Http\Controllers\Api\PlanningController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ChildController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ActivityController;
use Laravel\Sanctum\Sanctum;
use Illuminate\Support\Facades\Auth;

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('checklists', ChecklistController::class);
    Route::post('checklists/bulk-assign', [ChecklistController::class, 'bulkAssign']);
    Route::post('checklists/follow-up', [ChecklistController::class, 'followUp']);
    Route::apiResource('plannings', PlanningController::class);
    Route::apiResource('notifications', NotificationController::class);
    Route::apiResource('children', ChildController::class);
    Route::apiResource('users', UserController::class);
    Route::apiResource('activities', ActivityController::class);
});

// Endpoint login contoh
Route::post('login', function (\Illuminate\Http\Request $request) {
    $credentials = $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);
    if (!Auth::attempt($credentials)) {
        return response()->json(['message' => 'Unauthorized'], 401);
    }
    $user = Auth::user();
    $token = $user->createToken('api-token')->plainTextToken;
    return response()->json(['token' => $token, 'user' => $user]);
}); 
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AppointmentController;

// Public authentication routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {

    // Authentication
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Appointment management
    Route::get('/appointments', [AppointmentController::class, 'index']);
    Route::post('/appointments', [AppointmentController::class, 'store']);

    Route::get('/appointments/{appointment}', [
        AppointmentController::class,
        'show',
    ]);

    Route::post('/appointments/{appointment}/schedule', [
        AppointmentController::class,
        'schedule',
    ]);

    Route::post('/appointments/{appointment}/cancel', [
        AppointmentController::class,
        'cancel',
    ]);

    Route::post('/appointments/{appointment}/resolve-review', [
        AppointmentController::class,
        'resolveReview',
    ]);
});

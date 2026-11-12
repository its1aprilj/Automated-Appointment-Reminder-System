<?php

use App\Models\Appointment;
use App\Models\ReminderLog;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('dashboard');
});

Route::get('/dashboard', function () {
    $appointments = Appointment::latest()->get();

    $logs = ReminderLog::with('appointment')
        ->latest()
        ->take(15)
        ->get();

    $stats = [
        'total' => Appointment::count(),
        'scheduled' => Appointment::where('status', 'scheduled')->count(),
        'delivered' => Appointment::where('status', 'delivered')->count(),
        'retrying' => Appointment::where('status', 'retrying')->count(),
        'manual_review' => Appointment::where('status', 'manual_review')->count(),
        'expired' => Appointment::where('status', 'expired')->count(),
        'cancelled' => Appointment::where('status', 'cancelled')->count(),
    ];

    return view('dashboard', compact('appointments', 'logs', 'stats'));
})->name('dashboard');

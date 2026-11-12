<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Appointment extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'service',
        'destination',
        'appointment_at',
        'reminder_at',
        'status',
        'attempts',
        'max_attempts',
        'simulation_mode',
        'next_attempt_at',
        'delivered_at',
        'last_error',
    ];

    protected function casts(): array
    {
        return [
            'appointment_at' => 'datetime',
            'reminder_at' => 'datetime',
            'next_attempt_at' => 'datetime',
            'delivered_at' => 'datetime',
            'attempts' => 'integer',
            'max_attempts' => 'integer',
        ];
    }

    public function logs(): HasMany
    {
        return $this->hasMany(ReminderLog::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

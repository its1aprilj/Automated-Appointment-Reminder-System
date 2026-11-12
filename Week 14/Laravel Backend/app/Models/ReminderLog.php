<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReminderLog extends Model
{
    protected $fillable = [
        'appointment_id',
        'event',
        'level',
        'message',
        'attempt',
        'context',
    ];

    protected function casts(): array
    {
        return [
            'context' => 'array',
            'attempt' => 'integer',
        ];
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }
}

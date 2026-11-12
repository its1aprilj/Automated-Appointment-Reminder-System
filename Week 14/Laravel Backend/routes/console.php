<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Week 13: Automatically process appointment reminders every minute.
Schedule::command('appointments:process-reminders')
    ->everyMinute()
    ->withoutOverlapping();

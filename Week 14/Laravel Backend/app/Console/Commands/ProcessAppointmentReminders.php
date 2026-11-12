<?php

namespace App\Console\Commands;

use App\Models\Appointment;
use Illuminate\Console\Command;

class ProcessAppointmentReminders extends Command
{
    protected $signature = 'appointments:process-reminders
                            {--force-due : Ignore retry delays for local testing only}';

    protected $description =
        'Process due appointment reminders and close expired appointments.';

    public function handle(): int
    {
        $forceDue = (bool) $this->option('force-due');

        $expiredCount = $this->closeExpiredAppointments();

        $query = Appointment::query()
            ->whereIn('status', ['scheduled', 'retrying'])
            ->whereNotNull('next_attempt_at');

        if (!$forceDue) {
            $query->where('next_attempt_at', '<=', now());
        }

        $appointments = $query->orderBy('next_attempt_at')
            ->limit(100)
            ->get();

        $processed = 0;

        foreach ($appointments as $appointment) {
            $processed++;
            $attempt = $appointment->attempts + 1;
            $maxAttempts = max(1, (int) $appointment->max_attempts);

            // Stop reminders for appointments that expire before processing.
            if ($appointment->appointment_at->isPast()) {
                $this->expireAppointment($appointment);
                continue;
            }

            // Simulates a permanent failure, such as an invalid destination.
            if ($appointment->simulation_mode === 'permanent') {
                $appointment->update([
                    'attempts' => $attempt,
                    'status' => 'manual_review',
                    'next_attempt_at' => null,
                    'last_error' => 'Simulated permanent delivery failure.',
                ]);

                $this->writeLog(
                    $appointment,
                    'delivery_permanent_failure',
                    'warning',
                    'Permanent delivery failure. Manual review is required; no automatic retries remain.',
                    $attempt,
                    ['reason' => 'simulated_permanent_failure']
                );

                $this->warn("Appointment #{$appointment->id}: sent to manual review.");
                continue;
            }

            // Simulates temporary failures, followed by recovery on the
            // final permitted attempt (for the default limit, attempt 3).
            if (
                $appointment->simulation_mode === 'transient'
                && $attempt < $maxAttempts
            ) {
                $delaySeconds = 30 * $attempt;

                $appointment->update([
                    'attempts' => $attempt,
                    'status' => 'retrying',
                    'next_attempt_at' => now()->addSeconds($delaySeconds),
                    'last_error' => 'Simulated temporary delivery failure.',
                ]);

                $this->writeLog(
                    $appointment,
                    'delivery_transient_failure',
                    'warning',
                    "Temporary delivery failure. Retry scheduled in {$delaySeconds} seconds.",
                    $attempt,
                    [
                        'retry_delay_seconds' => $delaySeconds,
                        'max_attempts' => $maxAttempts,
                    ]
                );

                $this->warn(
                    "Appointment #{$appointment->id}: retry {$attempt}/{$maxAttempts} scheduled."
                );
                continue;
            }

            // Simulated success: normal mode succeeds immediately.
            // Transient mode reaches this block on its final attempt.
            $recovered = $appointment->simulation_mode === 'transient'
                && $attempt > 1;

            $appointment->update([
                'attempts' => $attempt,
                'status' => 'delivered',
                'delivered_at' => now(),
                'next_attempt_at' => null,
                'last_error' => null,
            ]);

            $event = $recovered
                ? 'delivery_recovered'
                : 'delivery_simulated';

            $message = $recovered
                ? "Simulated transient failure recovered on attempt {$attempt}."
                : 'Simulated reminder delivery succeeded. No external message was sent.';

            $this->writeLog(
                $appointment,
                $event,
                'info',
                $message,
                $attempt,
                [
                    'simulation_mode' => $appointment->simulation_mode,
                    'max_attempts' => $maxAttempts,
                ]
            );

            $this->info(
                "Appointment #{$appointment->id}: {$message}"
            );
        }

        $this->newLine();
        $this->info("Expired appointments closed: {$expiredCount}");
        $this->info("Reminder records processed: {$processed}");

        if ($forceDue) {
            $this->comment(
                'Testing option used: retry delays were ignored for this run.'
            );
        }

        return self::SUCCESS;
    }

    private function closeExpiredAppointments(): int
    {
        $expiredAppointments = Appointment::query()
            ->where('appointment_at', '<=', now())
            ->whereIn('status', ['scheduled', 'retrying'])
            ->get();

        foreach ($expiredAppointments as $appointment) {
            $this->expireAppointment($appointment);
        }

        return $expiredAppointments->count();
    }

    private function expireAppointment(Appointment $appointment): void
    {
        $appointment->update([
            'status' => 'expired',
            'next_attempt_at' => null,
            'last_error' => 'Appointment time has passed.',
        ]);

        $this->writeLog(
            $appointment,
            'appointment_expired',
            'warning',
            'Appointment expired and was closed. Pending reminders were disabled.',
            $appointment->attempts,
            ['appointment_at' => $appointment->appointment_at->toDateTimeString()]
        );

        $this->line("Appointment #{$appointment->id}: expired and closed.");
    }

    private function writeLog(
        Appointment $appointment,
        string $event,
        string $level,
        string $message,
        ?int $attempt,
        array $context = []
    ): void {
        $appointment->logs()->create([
            'event' => $event,
            'level' => $level,
            'message' => $message,
            'attempt' => $attempt,
            'context' => $context,
        ]);
    }
}

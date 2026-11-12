<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('reminder_logs', function (Blueprint $table) {
            $table->id();

            $table->foreignId('appointment_id')
                ->constrained('appointments')
                ->cascadeOnDelete();

            $table->string('event');
            $table->string('level')->default('info');
            $table->text('message');

            $table->unsignedTinyInteger('attempt')->nullable();
            $table->json('context')->nullable();

            $table->timestamps();

            $table->index(['appointment_id', 'event']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reminder_logs');
    }
};

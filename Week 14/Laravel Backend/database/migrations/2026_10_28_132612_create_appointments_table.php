<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();

            $table->string('name');
            $table->string('service');
            $table->string('destination');

            $table->dateTime('appointment_at')->index();
            $table->dateTime('reminder_at')->index();

            $table->string('status')->default('scheduled')->index();

            $table->unsignedTinyInteger('attempts')->default(0);
            $table->unsignedTinyInteger('max_attempts')->default(3);

            $table->string('simulation_mode')->default('success');

            $table->timestamp('next_attempt_at')->nullable()->index();
            $table->timestamp('delivered_at')->nullable();
            $table->text('last_error')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
};

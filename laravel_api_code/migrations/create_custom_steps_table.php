<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('custom_steps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('activity_id')->constrained('activities');
            $table->string('teacher_id');
            $table->json('steps');
            $table->timestamps();
        });
    }
    public function down()
    {
        Schema::dropIfExists('custom_steps');
    }
}; 
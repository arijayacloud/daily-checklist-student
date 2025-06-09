<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('planned_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('planning_id')->constrained('plannings');
            $table->foreignId('activity_id')->constrained('activities');
            $table->timestamp('scheduled_date');
            $table->string('scheduled_time')->nullable();
            $table->boolean('reminder')->default(true);
            $table->boolean('completed')->default(false);
            $table->timestamps();
        });
    }
    public function down()
    {
        Schema::dropIfExists('planned_activities');
    }
}; 
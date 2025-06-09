<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('follow_up_suggestions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children');
            $table->foreignId('completed_activity_id')->constrained('activities');
            $table->foreignId('suggested_activity_id')->constrained('activities');
            $table->boolean('auto_assigned')->default(false);
            $table->timestamp('assigned_date')->nullable();
            $table->timestamps();
        });
    }
    public function down()
    {
        Schema::dropIfExists('follow_up_suggestions');
    }
}; 
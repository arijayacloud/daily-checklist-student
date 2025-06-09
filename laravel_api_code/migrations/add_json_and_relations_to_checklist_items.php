<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::table('checklist_items', function (Blueprint $table) {
            $table->json('home_observation')->nullable()->after('status');
            $table->json('school_observation')->nullable()->after('home_observation');
            $table->json('custom_steps_used')->nullable()->after('school_observation');
            $table->foreignId('child_id')->nullable()->constrained('children')->after('id');
            $table->foreignId('activity_id')->nullable()->constrained('activities')->after('child_id');
        });
    }

    public function down()
    {
        Schema::table('checklist_items', function (Blueprint $table) {
            $table->dropColumn(['home_observation', 'school_observation', 'custom_steps_used']);
            $table->dropForeign(['child_id']);
            $table->dropForeign(['activity_id']);
            $table->dropColumn(['child_id', 'activity_id']);
        });
    }
}; 
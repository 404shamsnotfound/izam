<?php

namespace App\Listeners;

use App\Events\OrderPlaced;
use Illuminate\Support\Facades\Log;

class SendOrderNotification
{
    /**
     * Create the event listener.
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     */
    public function handle(OrderPlaced $event)
    {
        // In a real application, we would send an email to the admin
        // For this test task, we just log the event
        Log::info("Order placed", [
            "order_id" => $event->order->id,
            "user_id" => $event->order->user_id,
            "total" => $event->order->total,
        ]);
    }
}

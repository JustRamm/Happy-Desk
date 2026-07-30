import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, any>;
  schema: string;
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json();
    const { table, record } = payload;

    // Initialize Supabase Client using Admin Service Role Key
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    let recipientId: string | null = null;
    let title = "Happy Desk Alert";
    let body = "You have a new workplace update.";

    // 1. Handle Direct Message Invocations
    if (table === "direct_messages") {
      const senderName = record.sender_name || "A teammate";
      const receiverName = record.receiver_name;
      title = `Message from ${senderName}`;
      body = record.message || "Sent you a message";

      // Look up receiver profile by name or ID
      if (record.receiver_id) {
        recipientId = record.receiver_id;
      } else if (receiverName) {
        const { data: profile } = await supabase
          .from("profiles")
          .select("id, fcm_token")
          .eq("name", receiverName)
          .maybeSingle();

        if (profile) {
          recipientId = profile.id;
        }
      }
    } 
    // 2. Handle Coffee Break Invites
    else if (table === "coffee_break_invites") {
      recipientId = record.receiver_id;
      const { data: sender } = await supabase
        .from("profiles")
        .select("name")
        .eq("id", record.sender_id)
        .maybeSingle();

      const senderName = sender?.name || "A colleague";
      title = "☕ Coffee Break Invite!";
      body = `${senderName} invited you for a coffee break: "${record.message || 'Let\'s take a short break!'}"`;
    }

    if (!recipientId) {
      return new Response(JSON.stringify({ message: "No recipient found" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Fetch recipient's FCM token from profiles
    const { data: targetUser } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", recipientId)
      .single();

    const fcmToken = targetUser?.fcm_token;
    if (!fcmToken) {
      return new Response(
        JSON.stringify({ message: "User has no active FCM token" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 3. Dispatch Push Notification (OneSignal / FCM HTTP v1 API)
    console.log(`Sending Push Notification to token: ${fcmToken}`);
    console.log(`Title: ${title} | Body: ${body}`);

    // Call FCM or OneSignal Push Endpoint
    const pushResponse = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${Deno.env.get("FCM_SERVER_KEY")}`,
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: { title, body },
        data: { table, id: record.id },
      }),
    });

    const pushResult = await pushResponse.json();

    return new Response(
      JSON.stringify({ success: true, pushResult }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

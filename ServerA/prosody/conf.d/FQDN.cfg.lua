plugin_paths = {"/usr/lib/jitsi-meet-prosody-nightly"}

-- domain mapper options, must at least have domain base set to use the mapper
muc_mapper_domain_base = "<FQDN>";

external_service_secret = "__turnSecret__";
external_services = {{
    type = "stun",
    host = "<FQDN>",
    port = 3478
}, {
    type = "turn",
    host = "<FQDN>",
    port = 3478,
    transport = "udp",
    secret = true,
    ttl = 86400,
    algorithm = "turn"
}, {
    type = "turns",
    host = "<FQDN>",
    port = 5349,
    transport = "tcp",
    secret = true,
    ttl = 86400,
    algorithm = "turn"
}};

cross_domain_bosh = true;
consider_bosh_secure = true;
-- https_ports = { }; -- Remove this line to prevent listening on port 5284

-- https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.0g&guideline=5.4
ssl = {
    protocol = "tlsv1_2+",
    ciphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
}

consider_websocket_secure = true;
cross_domain_websocket = true;

VirtualHost "localhost"
    app_id = ""
    app_secret = ""
    authentication = "anonymous"
    modules_enabled = {"muc_size", "muc_custom_size"}

VirtualHost "stats.<FQDN>"
    app_id = ""
    app_secret = ""
    authentification = "anonymous"
    modules_enabled = {"muc_size", "muc_custom_size"}

VirtualHost "<FQDN>"
-- enabled = false -- Remove this line to enable this host
    authentication = "token"
    app_id = "<APP_NAME>"
    app_secret = "<APP_SECRET>"
    allow_empty_token = false
    -- Properties below are modified by jitsi-meet-tokens package config
    -- and authentication above is switched to "token"
    -- app_id="example_app_id"
    -- app_secret="example_app_secret"
    -- Assign this host a certificate for TLS, otherwise it would use the one
    -- set in the global section (if any).
    -- Note that old-style SSL on port 5223 only supports one certificate, and will always
    -- use the global one.
    ssl = {
        key = "/etc/prosody/certs/<FQDN>.key",
        certificate = "/etc/prosody/certs/<FQDN>.crt"
    }
    speakerstats_component = "speakerstats.<FQDN>"
    conference_duration_component = "conferenceduration.<FQDN>"
    -- we need bosh
    modules_enabled = {
        "bosh",
        "pubsub",
        "ping", -- Enable mod_ping
        "speakerstats",
        "external_services",
        "conference_duration",
        "muc_lobby_rooms",
        "presence_identity",
        "muc_size",
        "websocket"
    }
    c2s_require_encryption = false
    lobby_muc = "lobby.<FQDN>"
    main_muc = "conference.<FQDN>"

Component "conference.<FQDN>" "muc"
    storage = "memory"
    modules_enabled = {"muc_meeting_id", "muc_domain_mapper", "token_verification", "token_moderation"}
    admins = {"focus@auth.<FQDN>"}
    muc_room_locking = false
    muc_room_default_public_jids = true

-- internal muc component
Component "internal.auth.<FQDN>" "muc"
    storage = "memory"
    modules_enabled = {"ping"}
    admins = {"focus@auth.<FQDN>", "jvb@auth.<FQDN>"}
    muc_room_locking = false
    muc_room_default_public_jids = true

VirtualHost "auth.<FQDN>"
    ssl = {
        key = "/etc/prosody/certs/auth.<FQDN>.key",
        certificate = "/etc/prosody/certs/auth.<FQDN>.crt"
    }
    authentication = "internal_hashed"

-- Proxy to jicofo's user JID, so that it doesn't have to register as a component.
Component "focus.<FQDN>" "client_proxy"
    target_address = "focus@auth.<FQDN>"

Component "speakerstats.<FQDN>" "speakerstats_component"
    muc_component = "conference.<FQDN>"

Component "conferenceduration.<FQDN>" "conference_duration_component"
    muc_component = "conference.<FQDN>"

Component "lobby.<FQDN>" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true

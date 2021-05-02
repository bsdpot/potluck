#!/bin/sh

ASSUME_ALWAYS_YES=yes pkg bootstrap
touch /etc/rc.conf
sysrc sendmail_enable="NO"
sysrc jitsi_videobridge_enable="YES"
sysrc jitsi_videobridge_flags="--apis=rest,xmpp"
sysrc prosody_enable="YES"
sysrc jicofo_enable="YES"
sysrc -cq ifconfig_epair0b && sysrc -x ifconfig_epair0b || true

# Install packages
pkg install -y acme.sh nginx prosody jicofo jitsi-meet jitsi-videobridge 
pkg clean -y

#
# Now generate the run command script
# It configures the system on the first run and then starts nginx as process
# On subsequent runs, it only starts nginx
# 
echo "
#/bin/sh
if [ -e /usr/local/etc/pot-is-configured ]
then
    /usr/local/etc/rc.d/jitsi-videobridge start
    /usr/local/etc/rc.d/prosody start
    /usr/local/etc/rc.d/jicofo start
    nginx -g 'daemon off;'
    exit 0
fi

#
# Check config variables are set
# DOMAINNAME needs to contain the public domain name of the jail (e.g jitsi.honeyguide.net)
# PUBLICIP needs to contain the public IP address used to reach the service (for NAT traversal)
#

if [ -z \${DOMAINNAME+x} ]; 
then 
    echo 'DOMAINNAME is unset'
    exit 1
fi

if [ -z \${PUBLICIP+x} ]; 
then 
    echo 'PUBLICIP is unset'
    exit 1
fi

if [ -z \${PRIVATEIP+x} ];
then
    echo 'PRIVATEIP is unset'
    exit 1
fi

# Generate a password for stitching up the various parts of the configuration
KEYPASSWORD=\"\$(dd if=/dev/urandom count=1 2> /dev/null | uuencode -m - | sed -ne 2p | cut -c-12)\"

#
# Set up software
#

# Set up prosody
echo \"

pidfile = \\\"/var/run/prosody/prosody.pid\\\"
interfaces = { \\\"127.0.0.1\\\" }
admins = { \\\"focus@auth.\$DOMAINNAME\\\" }

modules_enabled = {

        -- Generally required
                \\\"roster\\\"; -- Allow users to have a roster. Recommended ;)
                \\\"saslauth\\\"; -- Authentication for clients and servers. Recommended if you want to log in.
                \\\"tls\\\"; -- Add support for secure TLS on c2s/s2s connections
                \\\"dialback\\\";
                \\\"carbons\\\"; -- Keep multiple clients in sync
                \\\"pep\\\"; -- Enables users to publish their avatar, mood, activity, playing music and more
                \\\"private\\\"; -- Private XML storage (for room bookmarks, etc.)
                \\\"blocklist\\\"; -- Allow users to block communications with other users
                \\\"vcard4\\\"; -- User profiles (stored in PEP)
                \\\"vcard_legacy\\\"; -- Conversion between legacy vCard and PEP Avatar, vcard

        -- Nice to have
                \\\"version\\\"; -- Replies to server version requests
                \\\"uptime\\\"; -- Report how long server has been running
                \\\"time\\\"; -- Let others know the time here on this server
                \\\"ping\\\"; -- Replies to XMPP pings with pongs
                \\\"register\\\"; -- Allow users to register on this server using a client and change passwords
                --\\\"mam\\\"; -- Store messages in an archive and allow users to access it
                --\\\"csi_simple\\\"; -- Simple Mobile optimizations

        -- Admin interfaces
                \\\"admin_adhoc\\\"; -- Allows administration via an XMPP client that supports ad-hoc commands
                --\\\"admin_telnet\\\"; -- Opens telnet console interface on localhost port 5582

        -- HTTP modules
                --\\\"bosh\\\"; -- Enable BOSH clients, aka Jabber over HTTP
                --\\\"websocket\\\"; -- XMPP over WebSockets
                --\\\"http_files\\\"; -- Serve static files from a directory over HTTP

        -- Other specific functionality
                --\\\"limits\\\"; -- Enable bandwidth limiting for XMPP connections
                --\\\"groups\\\"; -- Shared roster support
                --\\\"server_contact_info\\\"; -- Publish contact information for this service
                --\\\"announce\\\"; -- Send announcement to all online users
                --\\\"welcome\\\"; -- Welcome users who register accounts
                --\\\"watchregistrations\\\"; -- Alert admins of registrations
                --\\\"motd\\\"; -- Send a message to users when they log in
                --\\\"legacyauth\\\"; -- Legacy authentication. Only used by some old clients and bots.
                --\\\"proxy65\\\"; -- Enables a file transfer proxy service which clients behind NAT can use
}


c2s_require_encryption = true


s2s_require_encryption = true


s2s_secure_auth = false


--s2s_insecure_domains = { \\\"insecure.example\\\" }


authentication = \\\"internal_hashed\\\"


archive_expires_after = \\\"1w\\\" -- Remove archived messages after 1 week

log = {
        info = \\\"prosody.log\\\"; 
        error = \\\"prosody.err\\\";
        -- \\\"*syslog\\\"; -- Uncomment this for logging to syslog
        -- \\\"*console\\\"; -- Log to the console, useful for debugging with daemonize=false
}

certificates = \\\"certs\\\"


VirtualHost \\\"\$DOMAINNAME\\\"
    authentication = \\\"anonymous\\\"
    ssl = {
        key = \\\"/var/db/prosody/\$DOMAINNAME.key\\\";
        certificate = \\\"/var/db/prosody/\$DOMAINNAME.crt\\\";
    }
    modules_enabled = {
        \\\"bosh\\\";
        \\\"pubsub\\\";
    }
    c2s_require_encryption = false

VirtualHost \\\"auth.\$DOMAINNAME\\\"
    ssl = {
        key = \\\"/var/db/prosody/auth.\$DOMAINNAME.key\\\";
        certificate = \\\"/var/db/prosody/auth.\$DOMAINNAME.crt\\\";
    }
    authentication = \\\"internal_plain\\\"

admins = { \\\"focus@auth.\$DOMAINNAME\\\" }

Component \\\"conference.\$DOMAINNAME\\\" \\\"muc\\\"
Component \\\"jitsi-videobridge.\$DOMAINNAME\\\"
    component_secret = \\\"\$KEYPASSWORD\\\"
Component \\\"focus.\$DOMAINNAME\\\"
    component_secret = \\\"\$KEYPASSWORD\\\"
\" > /usr/local/etc/prosody/prosody.cfg.lua

echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate \$DOMAINNAME 
echo -ne '\n\n\n\n\n\n\n\n\n\n\n' | prosodyctl cert generate auth.\$DOMAINNAME 
prosodyctl register focus auth.\$DOMAINNAME \$KEYPASSWORD 

# Set up nginx
echo \"
worker_processes  1;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 80 default_server;

        server_name _;

        return 301 https://\\\$host\\\$request_uri;
    }

    server {
        listen 0.0.0.0:443 ssl http2;
        ssl_certificate      /usr/local/etc/ssl/\$DOMAINNAME.cer;
        ssl_certificate_key  /usr/local/etc/ssl/\$DOMAINNAME.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;

        server_name \$DOMAINNAME;
        # set the root
        root /usr/local/www/jitsi-meet;
        index index.html;
        location ~ ^/([a-zA-Z0-9=\?]+)$ {
            rewrite ^/(.*)$ / break;
        }
        location / {
            ssi on;
        }
        # BOSH, Bidirectional-streams Over Synchronous HTTP
        # https://en.wikipedia.org/wiki/BOSH_(protocol)
        location /http-bind {
            proxy_pass      http://localhost:5280/http-bind;
            proxy_set_header X-Forwarded-For \\\$remote_addr;
            proxy_set_header Host \\\$http_host;
        }
        # external_api.js must be accessible from the root of the
        # installation for the electron version of Jitsi Meet to work
        # https://github.com/jitsi/jitsi-meet-electron
        location /external_api.js {
            alias /srv/jitsi-meet/libs/external_api.min.js;
        }
    }
}\" > /usr/local/etc/nginx/nginx.conf

# Set up jitsi-videobridge
echo \"
JVB_XMPP_HOST=localhost
JVB_XMPP_DOMAIN=\$DOMAINNAME
JVB_XMPP_PORT=5347
JVB_XMPP_SECRET=\$KEYPASSWORD

VIDEOBRIDGE_MAX_MEMORY=3072m
\" > /usr/local/etc/jitsi/videobridge/jitsi-videobridge.conf

echo \"
org.jitsi.impl.neomedia.transform.srtp.SRTPCryptoContext.checkReplay=false
# The videobridge uses 443 by default with 4443 as a fallback, but since we're already
# running nginx on 443 in this example doc, we specify 4443 manually to avoid a race condition
org.jitsi.videobridge.TCP_HARVESTER_PORT=4443
org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=\$PRIVATEIP
org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=\$PUBLICIP

#
# For Grafana dashboard
#

# the callstats credentials
io.callstats.sdk.CallStats.appId=\"jistats\"
io.callstats.sdk.CallStats.keyId=\"jistats_\$KEYPASSWORD\"

# enable statistics and callstats statistics and the report interval
org.jitsi.videobridge.ENABLE_STATISTICS=true
org.jitsi.videobridge.STATISTICS_INTERVAL.callstats.io=30000
org.jitsi.videobridge.STATISTICS_TRANSPORT=callstats.io
\" > /usr/local/etc/jitsi/videobridge/sip-communicator.properties

# Set up jicofo
keytool -noprompt -keystore /usr/local/etc/jitsi/jicofo/truststore.jks -storepass \"\$KEYPASSWORD\" -importcert -alias prosody -file /var/db/prosody/auth.\$DOMAINNAME.crt

echo \"
JVB_XMPP_HOST=localhost
JVB_XMPP_DOMAIN=\$DOMAINNAME
JVB_XMPP_PORT=5347
JVB_XMPP_SECRET=\$KEYPASSWORD
JVB_XMPP_USER_DOMAIN=auth.\$DOMAINNAME
JVB_XMPP_USER_NAME=focus
JVB_XMPP_USER_SECRET=\$KEYPASSWORD

MAX_MEMORY=3072m
\" > /usr/local/etc/jitsi/jicofo/jicofo.conf

# Set up jitsi-meet
echo \"
/* eslint-disable no-unused-vars, no-var */

var config = {
    // Connection
    //

    hosts: {
        // XMPP domain.
        domain: '\$DOMAINNAME',


        bridge: 'jitsi-videobridge.\$DOMAINNAME',

        // Focus component domain. Defaults to focus.<domain>.
        focus: 'focus.\$DOMAINNAME',

        // XMPP MUC domain. FIXME: use XEP-0030 to discover it.
        muc: 'conference.\$DOMAINNAME'
    },

    // BOSH URL. FIXME: use XEP-0156 to discover it.
    bosh: '//\$DOMAINNAME/http-bind',

    // Websocket URL
    // websocket: 'wss://jitsi-meet.example.com/xmpp-websocket',

    // The name of client node advertised in XEP-0115 'c' stanza
    clientNode: 'http://jitsi.org/jitsimeet',

    // The real JID of focus participant - can be overridden here
    // focusUserJid: 'focus@auth.jitsi-meet.example.com',


    // Testing / experimental features.
    //

    testing: {
        // P2P test mode disables automatic switching to P2P when there are 2
        // participants in the conference.
        p2pTestMode: false

        // Enables the test specific features consumed by jitsi-meet-torture
        // testMode: false

        // Disables the auto-play behavior of *all* newly created video element.
        // This is useful when the client runs on a host with limited resources.
        // noAutoPlayVideo: false
    },

    // Disables ICE/UDP by filtering out local and remote UDP candidates in
    // signal
    // Disable measuring of audio levels.
    // disableAudioLevels: false,
    // audioLevelsInterval: 200,

    // Enabling this will run the lib-jitsi-meet no audio detection module which
    // will notify the user if the current selected microphone has no audio
    // input and will suggest another valid device if one is present.
    enableNoAudioDetection: true,

    // Enabling this will run the lib-jitsi-meet noise detection module which will
    // notify the user if there is noise, other than voice, coming from the current
    // selected microphone. The purpose it to let the user know that the input could
    // be potentially unpleasant for other meeting participants.
    enableNoisyMicDetection: true,

    // Start the conference in audio only mode (no video is being received nor
    // sent).
    // startAudioOnly: false,

    // Every participant after the Nth will start audio muted.
    // startAudioMuted: 10,

    // Start calls with audio muted. Unlike the option above, this one is only
    // applied locally. FIXME: having these 2 options is confusing.
    // startWithAudioMuted: false,

    // Enabling it (with #params) will disable local audio output of remote
    // participants and to enable it back a reload is needed.
    // startSilent: false

    // Video

    // Sets the preferred resolution (height) for local video. Defaults to 720.
    // resolution: 720,

    // w3c spec-compliant video constraints to use for video capture. Currently
    // used by browsers that return true from lib-jitsi-meet's
    // util#browser#usesNewGumFlow. The constraints are independent from
    // this config's resolution value. Defaults to requesting an ideal
    // resolution of 720p.

    // startVideoMuted: 10,

    // Start calls with video muted. Unlike the option above, this one is only
    // applied locally. FIXME: having these 2 options is confusing.
    // startWithVideoMuted: false,

    // If set to true, prefer to use the H.264 video codec (if supported).
    // Note that it's not recommended to do this because simulcast is not
    // supported when  using H.264. For 1-to-1 calls this setting is enabled by
    // default and can be toggled in the p2p section.
    // preferH264: true,

    // If set to true, disable H.264 video codec by stripping it out of the
    // SDP.
    // disableH264: false,

    // Desktop sharing

    // The ID of the jidesha extension for Chrome.
    desktopSharingChromeExtId: null,

    // Whether desktop sharing should be disabled on Chrome.
    // desktopSharingChromeDisabled: false,

    // The media sources to use when using screen sharing with the Chrome
    // extension.
    desktopSharingChromeSources: [ 'screen', 'window', 'tab' ],

    // Required version of Chrome extension
    desktopSharingChromeMinExtVersion: '0.1',

    // Whether desktop sharing should be disabled on Firefox.
    // desktopSharingFirefoxDisabled: false,

    // Optional desktop sharing frame rate options. Default value: min:5, max:5.
    // desktopSharingFrameRate: {
    //     min: 5,
    //     max: 5
    // },


    //     // A URL to redirect the user to, after authenticating
    //     // by default uses:
    //     // 'https://jitsi-meet.example.com/static/oauth.html'
    //     redirectURI:
    //          'https://jitsi-meet.example.com/subfolder/static/oauth.html'
    // },
    // When integrations like dropbox are enabled only that will be shown,
    // by enabling fileRecordingsServiceEnabled, we show both the integrations
    // and the generic recording service (its configuration and storage type
    // depends on jibri configuration)
    // fileRecordingsServiceEnabled: false,
    // Whether to show the possibility to share file recording with other people
    // (e.g. meeting participants), based on the actual implementation
    // on the backend.
    // fileRecordingsServiceSharingEnabled: false,

    // Whether to enable live streaming or not.
    liveStreamingEnabled: true,

    // Transcription (in interface_config,
    // subtitles and buttons can be configured)
    // transcribingEnabled: false,

    // Enables automatic turning on captions when recording is started
    // autoCaptionOnRecord: false,

    // Misc

    // Default value for the channel \\\"last N\\\" attribute. -1 for unlimited.
    channelLastN: -1,

    // Disables or enables RTX (RFC 4588) (defaults to false).
    // disableRtx: false,

    // Disables or enables TCC (the default is in Jicofo and set to true)
    // (draft-holmer-rmcat-transport-wide-cc-extensions-01). This setting
    // affects congestion control, it practically enables send-side bandwidth
    // estimations.
    // enableTcc: true,

    //
    // useIPv6: true,

    // Enables / disables a data communication channel with the Videobridge.
    // Values can be 'datachannel', 'websocket', true (treat it as
    // 'datachannel'), undefined (treat it as 'datachannel') and false (don't
    // open any channel).
    // openBridgeChannel: true,


    // UI
    //

    // Use display name as XMPP nickname.
    // useNicks: false,

    // Require users to always specify a display name.
    // requireDisplayName: true,

    // Whether to use a welcome page or not. In case it's false a random room
    // will be joined when no room is specified.
    enableWelcomePage: true,

    // Enabling the close page will ignore the welcome page redirection when
    // a call is hangup.
    // enableClosePage: false,

    // Disable hiding of remote thumbnails when in a 1-on-1 conference call.
    // disable1On1Mode: false,

    // Default language for the user interface.
    // defaultLanguage: 'en',

    // If true all users without a token will be considered guests and all users
    // with token will be considered non-guests. Only guests will be allowed to
    // edit their profile.
    enableUserRolesBasedOnToken: false,

    // Whether or not some features are checked based on token.
    // enableFeaturesBasedOnToken: false,

   
    // and microsoftApiApplicationClientID
    // enableCalendarIntegration: false,

    // Stats
    //

    // Whether to enable stats collection or not in the TraceablePeerConnection.
    // This can be useful for debugging purposes (post-processing/analysis of
    // the webrtc stats) as it is done in the jitsi-meet-torture bandwidth
    // estimation tests.
    // gatherStats: false,

    // The interval at which PeerConnection.getStats() is called. Defaults to 10000
    // pcStatsInterval: 10000,

    // To enable sending statistics to callstats.io you must provide the
    // Application ID and Secret.
    callStatsID: 'jistats',
    callStatsSecret: 'jistats_\$KEYPASSWORD',

    // enables sending participants display name to callstats
    // enableDisplayNameInStats: false,

    // enables sending participants email if available to callstats and other analytics
    // enableEmailInStats: false,

    // Privacy
    //

    // If third party requests are disabled, no other server will be contacted.
    // This means avatars will be locally generated and callstats integration
    // will not function.
    // disableThirdPartyRequests: false,


    // Peer-To-Peer mode: used (if enabled) when there are just 2 participants.
    //

    p2p: {
        // Enables peer to peer mode. When enabled the system will try to
        // establish a direc
        // useStunTurn: true,

        // The STUN servers that will be used in the peer to peer connections
        stunServers: [

            // { urls: 'stun:jitsi-meet.example.com:4446' },
            { urls: 'stun:meet-jit-si-turnrelay.jitsi.net:443' }
        ],

        // Sets the ICE transport policy for the p2p connection. At the time
        // of this writing the list of possible values are 'all' and 'relay',
        // but that is subject to change in the future. The enum is defined in
        // the WebRTC standard:
        // https://www.w3.org/TR/webrtc/#rtcicetransportpolicy-enum.
        // If not set, the effective value is 'all'.
        // iceTransportPolicy: 'all',

        // If set to true, it will prefer to use H.264 for P2P calls (if H.264
        // is supported).
        preferH264: true

        // If set to true, disable H.264 video codec by stripping it out of the
        // SDP.
        // disableH264: false,

        // How long we're going to wait, before going back to P2P after the 3rd
        // participant has left the conference (to filter out page reload).
        // backToP2PDelay: 5
    },

    analytics: {
        // The Google Analytics Tracking ID:
        // googleAnalyticsTrackingId: 'your-tracking-id-UA-123456-1'

        // The Amplitude APP Key:
        // amplitudeAPPKey: '<APP_KEY>'


    //     // Extensions info which allows checking if they are installed or not
    //     chromeExtensionsInfo: [
    //         {
    //             id: 'kglhbbefdnlheedjiejgomgmfplipfeb',
    //             path: 'jitsi-logo-48x48.png'
    //         }
    //     ]
    },

    // Local Recording
    //

    // localRecording: {
    // Enables local recording.
    // Additionally, 'localrecording' (all lowercase) needs to be added to
    // TOOLBAR_BUTTONS in interface_config.js for the Local Recording
    // button to show up on the toolbar.
    //
    //     enabled: true,
    //

    // The recording format, can be one of 'ogg', 'flac' or 'wav'.
    //     format: 'flac'
    //

    // },

    // Options related to end-to-end (participant to participant) ping.
    // e2eping: {
    //   // The interval in milliseconds at which pings will be sent.
    //   // Defaults to 10000, set to <= 0 to disable.
    //   pingInterval: 10000,
    //
    //   // The interval in milliseconds at which analytics events
    //   // with the measured RTT will be sent. Defaults to 60000, set
    //   // to <= 0 to disable.
    //   analyticsInterval: 60000,
    //   },

    // If set, will attempt to use the provided vi
    // and instead the app will continue to display in the current browser.
    // disableDeepLinking: false,

    // A property to disable the right click context menu for localVideo
    // the menu has option to flip the locally seen video for local presentations
    // disableLocalVideoFlip: false,

    // Mainly privacy related settings

    // Disables all invite functions from the app (share, invite, dial out...etc)
    // disableInviteFunctions: true,

    // Disables storing the room name to the recents list
    // doNotStoreRoom: true,

    // Deployment specific URLs.
    // deploymentUrls: {
    //    // If specified a 'Help' button will be displayed in the overflow menu with a link to the specified URL for
    //    // user documentation.
    //    userDocumentationURL: 'https://docs.example.com/video-meetings.html',
    //    // If specified a 'Download our apps' button will be displayed in the overflow menu with a link
    //    // to the specified URL for an app download page.
    //    downloadAppsUrl: 'https://docs.example.com/our-apps.html'
    // },

    // Options related to the remote participant menu.
    // remoteVideoMenu: {
    //     // If set to true the 'Kick out' button will be disabled.
    //     disableKick: true
    // },

    // If set to true all muting operations of remote participants will be disabled.
    // disableRemoteMute: true,

    // List of undocumented settings used in jitsi-meet
    /**
     _immediateReloadThreshold
     autoRecord
     autoRecordToken
     debug
     debugAudioLev
     iAmSipGateway
     microsoftApiApplicationClientID
     peopleSearchQueryTypes
     peopleSearchUrl
     requireDisplayName
     tokenAuthUrl
     */

    // List of undocumented settings used in lib-jitsi-meet
    /**
     _peerConnStatusOutOfLastNTimeout
     _peerConnStatusRtcMuteTimeout
     abTesting
     avgRtpStatsN
     callStatsConfIDNamespace
     callStatsCustomScriptUrl
     desktopSharingSources
     disableAEC
     disableAGC
     disableAP
     disableHPF
     disableNS
     enableLipSync
     enableTalkWhileMuted
     forceJVB121Ratio
     hiddenDomain
     ignoreStartMuted
     nick
     startBitrate
     */


    // Allow all above example options to include a trailing comma and
    // prevent fear when commenting out the last value.
    makeJsonParserHappy: 'even if last key had a trailing comma'

    // no configuration value should follow this line.
};

/* eslint-enable no-unused-vars, no-var */
\" > /usr/local/www/jitsi-meet/config.js

# Fetch certificates
cd /tmp
acme.sh --force --issue -d \$DOMAINNAME --standalone
mv /root/.acme.sh/\$DOMAINNAME/* /usr/local/etc/ssl/

# Never run this script again on boot
touch /usr/local/etc/pot-is-configured

/usr/local/etc/rc.d/jitsi-videobridge start
/usr/local/etc/rc.d/prosody start
/usr/local/etc/rc.d/jicofo start

nginx -g 'daemon off;'

" > /usr/local/bin/cook
chmod u+x /usr/local/bin/cook

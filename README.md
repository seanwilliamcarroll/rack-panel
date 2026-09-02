# rack-panel

A wall dashboard for a homelab rack display. Runs on a Raspberry Pi driving a
1080p panel in kiosk mode.

## Architecture

Collectors run on systemd timers and write JSON to a directory. A web server
serves that directory as static files. The page fetches them with JavaScript.

    systemd timer -> collector script -> /var/lib/panel-data/*.json
                                                 |
                                           static file server
                                                 |
                                           browser fetch()

No backend service. A failed collector leaves the previous JSON in place, so the
page shows stale data rather than an error. No CORS, since data and page share an
origin. No credentials in the browser.

## Setup

    cp config.example.js config.js
    cp collect/config.example.env collect/config.env

Edit both, then install the systemd units from `systemd/` and point a web server
at the repo root.

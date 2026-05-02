import http.server
import socketserver
import os

PORT = int(os.environ.get("PORT", 10000))

class HealthCheckHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"OK - Merlin C2 Sidecar Running")

    def log_message(self, format, *args):
        return

print(f"[*] Health Check Sidecar ouvindo na porta {PORT}")
with socketserver.TCPServer(("0.0.0.0", PORT), HealthCheckHandler) as httpd:
    httpd.serve_forever()

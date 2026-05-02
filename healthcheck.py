import http.server
import socketserver
import os
import sys

# O Render injeta a porta na variável de ambiente PORT
PORT = int(os.environ.get("PORT", 10000))

class HealthCheckHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"OK")

    def log_message(self, format, *args):
        # Silencia logs para economizar RAM/I/O
        return

print(f"[*] Sidecar Health Check ativo na porta {PORT}")
try:
    with socketserver.TCPServer(("0.0.0.0", PORT), HealthCheckHandler) as httpd:
        httpd.serve_forever()
except Exception as e:
    print(f"[!] Erro no sidecar: {e}")
    sys.exit(1)

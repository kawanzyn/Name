"""Small HTTP API for the Sea Beast puzzle solver."""
import hmac
import os

from flask import Flask, jsonify, request
from solver import solve_safe

app = Flask(__name__)
API_TOKEN = os.environ.get("API_TOKEN", "")


@app.get("/")
def health():
    return jsonify({"service": "sea-beast-solver", "status": "online"})


@app.post("/solve")
def solve_route():
    if API_TOKEN:
        supplied = request.headers.get("X-API-Key", "")
        if not hmac.compare_digest(supplied, API_TOKEN):
            return jsonify({"ok": False, "error": "unauthorized"}), 401

    payload = request.get_json(silent=True) or {}
    board = payload.get("board")
    time_limit = payload.get("time_limit", 8)
    node_limit = payload.get("node_limit", 8_000_000)

    try:
        result = solve_safe(board, time_limit=time_limit, node_limit=node_limit)
    except Exception:
        app.logger.exception("solver failure")
        return jsonify({"ok": False, "error": "internal solver error"}), 500

    return jsonify(result), (200 if result.get("ok") else 422)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    app.run(host="0.0.0.0", port=port)

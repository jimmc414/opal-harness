from flask import Flask, jsonify

app = Flask(__name__)


@app.route('/')
def index():
    return jsonify({"message": "Welcome"})


@app.route('/api/status')
def status():
    return jsonify({"status": "ok"})

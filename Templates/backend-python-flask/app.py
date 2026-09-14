from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

TEMPLATE = """<!DOCTYPE html>
<html>
<head><title>{{PROJECT_NAME}}</title></head>
<body style="font-family: sans-serif; text-align: center; padding: 3rem;">
  <h1>{{PROJECT_NAME}}</h1>
  <p>Flask 3 web application running smoothly.</p>
</body>
</html>"""

@app.route("/")
def home():
    return render_template_string(TEMPLATE)

@app.route("/api/status")
def status():
    return jsonify({"service": "{{PROJECT_NAME}}", "status": "active"})

if __name__ == "__main__":
    app.run(debug=True, port=5000)

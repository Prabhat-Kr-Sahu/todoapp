from flask import Flask
from config import Config
from models import db
from auth import bp as auth_bp
from routes import bp as api_bp
from flask_jwt_extended import JWTManager

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    db.init_app(app)
    jwt = JWTManager(app)
    app.register_blueprint(auth_bp)
    app.register_blueprint(api_bp)

    @app.route('/')
    def index():
        return "Todo API is running"

    return app

if __name__ == '__main__':
    app = create_app()
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000)

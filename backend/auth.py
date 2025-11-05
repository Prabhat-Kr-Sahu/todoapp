from flask import Blueprint, request, jsonify
from models import db, User
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token

bp = Blueprint("auth", __name__)


@bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    username = data["username"]
    password = data["password"]
    if User.query.filter_by(username=username).first():
        return jsonify({"msg": "user exists"}), 400
    user = User(username=username, password_hash=generate_password_hash(password))
    db.session.add(user)
    db.session.commit()
    return jsonify({"msg": "registered"}), 201


@bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data["username"]).first()
    if not user or not check_password_hash(user.password_hash, data["password"]):
        return jsonify({"msg": "bad creds"}), 401
    token = create_access_token(identity=str(user.id))
    return jsonify(access_token=token)

from flask import Blueprint, request, jsonify
from models import db, Todo
from flask_jwt_extended import jwt_required, get_jwt_identity

bp = Blueprint("api", __name__, url_prefix="/api")


@bp.route("/todos", methods=["GET"])
@jwt_required()
def list_todos():
    uid = get_jwt_identity()
    todos = Todo.query.filter_by(user_id=uid).all()
    return jsonify(
        [{"id": t.id, "title": t.title, "completed": t.completed} for t in todos]
    )


@bp.route("/todos", methods=["POST"])
@jwt_required()
def create_todo():
    uid = get_jwt_identity()
    data = request.get_json()
    if not data or "title" not in data:
        return jsonify({"error": "title is required"}), 400
    t = Todo(title=data["title"], user_id=uid)
    db.session.add(t)
    db.session.commit()
    return jsonify({"id": t.id, "title": t.title, "completed": t.completed}), 201


@bp.route("/todos/<int:tid>", methods=["PUT"])
@jwt_required()
def update_todo(tid):
    uid = get_jwt_identity()
    t = Todo.query.filter_by(id=tid, user_id=uid).first_or_404()
    data = request.get_json()
    t.title = data.get("title", t.title)
    t.completed = data.get("completed", t.completed)
    db.session.commit()
    return jsonify({"msg": "updated"})


@bp.route("/todos/<int:tid>", methods=["DELETE"])
@jwt_required()
def delete_todo(tid):
    uid = get_jwt_identity()
    t = Todo.query.filter_by(id=tid, user_id=uid).first_or_404()
    db.session.delete(t)
    db.session.commit()
    return jsonify({"msg": "deleted"})

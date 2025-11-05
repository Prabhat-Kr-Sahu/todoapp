def register(client, username="user", password="pass"):
    return client.post("/register", json={"username": username, "password": password})


def login(client, username="user", password="pass"):
    return client.post("/login", json={"username": username, "password": password})


def test_register_login_and_crud(client):
    # register
    r = register(client)
    assert r.status_code == 201
    print("Register response:", r.get_json())

    # login
    r = login(client)
    assert r.status_code == 200
    print("Login response:", r.get_json())
    token = r.get_json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # create todo
    r = client.post("/api/todos", json={"title": "task1"}, headers=headers)
    print("Create todo response:", r.get_json(), "Status:", r.status_code)
    assert r.status_code == 201
    todo = r.get_json()
    assert todo["title"] == "task1"

    tid = todo["id"]

    # list todos
    r = client.get("/api/todos", headers=headers)
    assert r.status_code == 200
    assert len(r.get_json()) == 1

    # update todo
    r = client.put(f"/api/todos/{tid}", json={"completed": True}, headers=headers)
    assert r.status_code == 200

    # delete todo
    r = client.delete(f"/api/todos/{tid}", headers=headers)
    assert r.status_code == 200

    # list -> empty
    r = client.get("/api/todos", headers=headers)
    assert r.status_code == 200
    assert len(r.get_json()) == 0

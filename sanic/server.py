from sanic import Sanic

app = Sanic()


app.static("/", "static/index.html", content_type="text/html; charset=utf-8")


def main():
    app.run(host="0.0.0.0", port=8000, workers=4)


if __name__ == "__main__":
    main()

import os
import glob
from sanic import Sanic, response

app = Sanic()


app.static("/", "static/index.html", content_type="text/html; charset=utf-8")
app.static("/static", "/usr/src/app/static")


def main():
    app.run(host="0.0.0.0", port=8000, workers=4)


@app.route("/farm")
def farm(request):
    pic_filenames = [
        os.path.basename(x) for x in glob.glob("/usr/src/app/static/farm/*")
    ]

    html = ""
    for pic in pic_filenames:
        html = "{} <img src='/static/farm/{}' height=auto width=40%></img>".format(
            html, pic
        )
    return response.html(html)


if __name__ == "__main__":
    main()

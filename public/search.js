var xhr = new XMLHttpRequest();

function doSearch() {
    t = document.getElementById("searchword").value;
    if (t.length != 0) {
        xhr.onreadystatechange = checkStatus;
        xhr.open('GET', 'http://' + window.location.hostname + ':9998/search/' + t, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }
}

function checkStatus() {
    str = "";
    if ((xhr.readyState == 4) && (xhr.status == 200)){
        a = xhr.response;
        len = a[0].kensu;
        if (len == 0){
            str = "見つかりませんでした。キーワードを変えてみてください。";
        } else {
            str = str + len + "件見つかりました。<br>";
            if (len <= 100){
                for (i = 1; i <= len; i++) {
                    str = str + "<a href=\"/codepage/" + a[i].id + "\">このコードを見てみる</a><br>";
                    //str = str + "<a href=\"/codepage/" + a[i].id +" ">" + \">このコードを見てみる</a><br>";
                    //str = str + a[i].id;
                    //str = str + ">このコードを見てみる</a><br>";
                    //str = str + C;
                    //str = str + "このコードを見てみる";
                    //str = str + "</a><br>";
                    str = str + "<pre class=\"prettyprint linenums\">";
                    str = str + a[i].code;
                    str = str + "</pre><br>";
                }
            }
        }
        document.getElementById("result").innerHTML = str;
    }
}
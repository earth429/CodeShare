// ログアウトしてよいか確認
function logoutConfirm() {
    if (window.confirm("本当にログアウトしてもよいですか？")) {
        window.alert("ログアウトしました");
        return true;
    } else {
        window.alert("ログアウトをキャンセルしました");
        return false;
    }
}

// 共有されたコードを削除してよいか確認
function deleteConfirm() {
    if (window.confirm("本当に削除してもよいですか？")){
        window.alert("削除しました");
        return true;
    } else {
        window.alert("削除をキャンセルしました");
        return false;
    }
}

// コードを共有していいか確認
function postConfirm() {
    if (window.confirm("本当に共有してもよいですか？")) {
        window.alert("コードを共有しました！\nコードページに移動します");
        return true;
    } else {
        window.alert("共有をキャンセルしました");
        return false;
    }
}

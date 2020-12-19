require 'sinatra'
require 'digest/md5'
require 'active_record'
require 'securerandom'
require "cgi/escape"
require 'pp'

set :environment, :production
set :sessions,
    expire_after: 7200,
    secret: 'abcdefghij0123456789'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

# ActiveRecordのBaseを継承
class Account < ActiveRecord::Base
end

class Code < ActiveRecord::Base
end

# パスワードがデータベースにあるかチェック
def checkpass(trial_username, trial_passwd)
    # 登録されている情報の確認
    begin
        a = Account.find(trial_username)
        db_username = a.id
        db_salt = a.salt
        db_hashed = a.hashed
        db_algo = a.algo
    rescue => e # アカウントが見つからない例外発生
        puts "User #{trial_username} is not found."
        return false
    end

    # ハッシュ値生成
    if db_algo == "1"
        trial_hashed = Digest::MD5.hexdigest(db_salt + trial_passwd)
    else
        puts "Unknown algorithm is used for user #{trial_username}"
        return false
    end

    # Display internal variables
    puts "--- DB ---"
    puts "username = #{db_username}"
    puts "salt = #{db_salt}"
    puts "algorithm = #{db_algo}"
    puts "hashed passwd = #{db_hashed}"
    puts ""
    puts "--- TRIAL ---"
    puts "username = #{trial_username}"
    puts "passwd = #{trial_passwd}"
    puts "hashed passwd = #{trial_hashed}"
    puts ""

    # ログインに成功したか
    if db_hashed == trial_hashed
        puts "Login Success"
        return true
    else
        return false
    end
end

# ユーザー登録
def registeruser(regi_username, regi_passwd)
    # 登録されているか確認
    begin
        a = Account.find(regi_username)
        redirect '/registerfailure'
        return false
    rescue => e # アカウントが見つからない場合(このとき登録)
        # 基本情報
        username = regi_username
        rawpasswd = regi_passwd
        algorithm = "1"
        r = Random.new
        salt = Digest::MD5.hexdigest(r.bytes(20))
        hashed = Digest::MD5.hexdigest(salt + rawpasswd)

        puts "salt = #{salt}"
        puts "username = #{username}"
        puts "raw password = #{rawpasswd}"
        puts "algorithm = #{algorithm}"
        puts "hashed passwd = #{hashed}"

        # データベースのアップデート
        s = Account.new
        s.id = username
        s.salt = salt
        s.hashed = hashed
        s.algo = algorithm
        s.save

        # 登録されているデータベースの表示
        @s = Account.all
        @s.each do |a|
            puts a.id + "\t" + a.salt + "\t" + a.hashed + "\t" + a.algo
        end
        return true
    end
end


get '/' do
    redirect '/login'
end

get '/login' do
    erb :login
end

# ログイン認証
post '/auth' do
    username = params[:uname]
    pass = params[:pass]

    if (checkpass(username, pass)) # パスワードチェック
        session[:login_flag] = true
        session[:username] = username
        redirect '/contentspage'
    else
        session[:login_flag] = false
        redirect '/loginfailure'
    end
end

# ログイン失敗
get '/loginfailure' do
    erb :loginfailure
end

# 登録ページ
get '/registerpage' do
    erb :registerpage
end

# ユーザー登録
post '/register' do
    username = params[:uname]
    pass = params[:pass]

    if (registeruser(username, pass)) # 登録に成功するか
        redirect '/registersuccess'
    else
        redirect '/registerfailure'
    end
end

get '/registersuccess' do
    erb :registersuccess
end

get '/registerfailure' do
    erb :registerfailure
end

get '/contentspage' do
    if (session[:login_flag] == true)
        @c = Code.all
        @username = session[:username]
        erb :index
    else
        erb :badrequest
    end
end

post '/new' do
    # 時間の取得
    time = Time.now

    # ランダムな hex 文字列をIDに付与
    id = SecureRandom.hex(10)

    # 書き込まれたタイトルとコードを変数に格納
    title = params[:title]
    code = params[:code]

    # 文字数を超えないように制限
    """if title.length >= 200
        title = title.slice(0..199)
    elsif code.length >= 500
        code = code.slice(0..499)
    end"""

    # サニタイジング
    title = CGI.escapeHTML(title)
    code = CGI.escapeHTML(code)

    # 改行の対応
    code = code.gsub(/(\r\n|\n|\r)/, '<br>')
    
    c = Code.new
    if title == ""
        c.title = "タイトルなし" # もしも名前が書き込まれなかったら
    else
        c.title = title
    end
    
    # データベースへ保存
    c.id = id
    c.username = session[:username]
    c.write_time = time
    c.code = code
    c.save
    redirect '/codepage/' + id
end

get '/codepage/:id' do
    if (session[:login_flag] == true)
        puts 'これがid'
        puts params[:id]
        @thiscode = Code.find_by(id: params[:id])
        #@code = Code.where(username: session[:username])
        pp @thiscode
        @username = session[:username]
        erb :codepage
    else
        erb :badrequest
    end
end

delete '/del' do
    c = Code.find(params[:id])
    c.destroy
    redirect '/contentspage'
end

get '/error' do
    erb :error
end

get '/logout' do
    session.clear
    erb :logout
end

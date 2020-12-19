require 'sinatra'
require 'digest/md5'
require 'active_record'

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

    # Generate a hashed value
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

    # Success?
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

    if (checkpass(username, pass)) # password check
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
    # 書き込まれた書き込みの一つ前の書き込みのIDを取得
    id_count = Code.select('id').last

    # 最初の書き込みだったらID:1を付与
    if id_count != nil
        id_count = id_count.id
    else
        id_count = 1
    end

    # 書き込み数が1000件超えるとき
    if id_count != nil and id_count > 999
        redirect '/error'
    end

    # 書き込まれたタイトルとコードを変数に格納
    title = params[:title]
    code = params[:code]

    pp params[:title]
    pp params[:code]

    # 文字数を超えないように制限
    """if title.length >= 200
        title = title.slice(0..199)
    elsif code.length >= 500
        code = code.slice(0..499)
    end"""

    # 改行の対応
    code = code.gsub(/(\r\n|\n|\r)/, '<br>')
    
    c = Code.new
    if title == ""
        c.title = "Untitled" # もしも名前が書き込まれなかったら
    else
        c.title = title
    end
    
    c.write_time = time
    c.code = code
    c.save
    redirect '/contentspage'
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

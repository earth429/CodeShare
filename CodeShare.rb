require 'sinatra'
require 'active_record'

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

# ActiveRecordのBaseを継承
class Code < ActiveRecord::Base
end

get '/'do
    @s = Code.all
    erb :index
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
    
    s = Code.new
    if title == ""
        s.title = "Untitled" # もしも名前が書き込まれなかったら
    else
        s.title = title
    end
    
    s.write_time = time
    s.code = code
    s.save
    redirect '/'
end

delete '/del' do
    s = Code.find(params[:id])
    s.destroy
    redirect '/'
end

get '/error' do
    erb :error
end

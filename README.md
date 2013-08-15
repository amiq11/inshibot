inshibot
=========

院試(情報理工学系研究科)までのカウントダウンをつぶやくbotのソース


概要
----
sqliteの使い方、およびOAuthでの認証の仕方の練習を兼ねて作ったbot。

 
環境
----
* 前提  
ruby1.9.3がインストール済み
(動作確認は2.0.0でもしています)
* インストール  
以下のコマンドを打てばいいはず。

> bundle install --path vender/bundle

bundleが入っていない人はgem install bundlerでインストールしてください。

実行
----
以下のコマンドだけで動作します。
> bundle exec ./inshibot.rb

ssh越しに、サーバ上でバックグラウンドで動作させたい場合は以下のようにしてみてください。  
> nohup bundle exec ./inshibot.rb &


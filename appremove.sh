#! /bin/bash
declare -a carrier_app_name=("docomo" "ntt" "auone" "rakuten" "kddi" "softbank" "taginfo") 

# adbが存在するか確認
which adb > /dev/null 2>&1
if [ $? -eq 1 ]
then
    echo "adbコマンドが存在しません"
    echo -n "adbコマンドを自動でインストールしますか? [y/n] : "
    read answer
    if [ $answer = "y" ] || [ $answer = "Y" ]
    then
        echo "adbコマンドをインストールします"
        case `uname -s` in
            Darwin)
                brew install android-platform-tools
                ;;
            Linux)
                # redhatかarchかubuntuか
                if [ -e /etc/redhat-release ]
                then
                    sudo yum install android-tools
                elif [ -e /etc/arch-release ]
                then
                    sudo pacman -S android-tools
                elif [ -e /etc/lsb-release ]
                then
                    sudo apt-get install android-tools-adb
                else
                    echo "このOSは対応していません"
                    exit 1
                fi
                ;;
            *)
                echo "このOSは対応していません"
                exit 1
                ;;
        esac
    elif [ $answer = "n" ] || [ $answer = "N" ]
    then
        echo "adbコマンドをインストールを中止しました"
        exit 0
    else
        echo "不正な入力です"
        echo "処理を中止しました"
        exit 1
    fi
fi

# デバイスが接続されているか確認
adb shell exit > /dev/null 2>&1
if [ $? -eq 1 ]
then
    echo "デバイスが接続されていません"
    exit 1
fi

adb shell pm list package >> pkg.txt
adb shell pm list package -f >> backup.txt

# パッケージ名の一覧を取得
for i in "${carrier_app_name[@]}"
do
    cat pkg.txt | sed "s/package://g" | grep $i >> name.txt
done
rm pkg.txt

# パッケージのパスを取得
for i in "${carrier_app_name[@]}"
do
    cat backup.txt | sed "s/package://g" | sed "s/apk=.*$//g" | sed "s/$/apk/g" | grep $i >> path.txt
done
rm backup.txt

# バックアップスクリプトを生成
paste path.txt name.txt | sed "s/^/adb pull /g" | sed "s/$/.apk/g" > backup.sh
echo "mkdir backup" >> backup.sh
echo "mv *.apk backup" >> backup.sh
rm path.txt

# 削除スクリプトを生成
cat name.txt | sed "s/^/adb shell pm uninstall --user 0 /g" > remove.sh

# バックアップスクリプトを実行
cat name.txt
echo -n "アプリのバックアップを取得しますか? [Y/n] : "
read answer
if [ $answer = "Y" ] || [ $answer = "y" ]
then
    echo "スマホでバックアップを認可してください"
    sh backup.sh
    rm backup.sh
    echo "アプリのバックアップを実行しました"
elif [ $answer = "N" ] || [ $answer = "n" ]
then
    rm backup.sh 
else
    rm backup.sh name.txt remove.sh
    echo "不正な入力です"
    echo "処理を中止しました"
    exit 1
fi

# 削除スクリプトを実行
cat name.txt
echo -n "アプリを削除しますか? [Y/n] : "
read answer
if [ $answer = "Y" ] || [ $answer = "y" ]
then
    sh remove.sh
    rm remove.sh name.txt
    echo "アプリを削除しました"
elif [ $answer = "N" ] || [ $answer = "n" ]
then
    rm remove.sh name.txt
else
    rm remove.sh name.txt
    echo "不正な入力です"
    echo "処理を中止しました"
    exit 1
fi
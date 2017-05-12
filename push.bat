cd .\log

del . /q

cd ..

git add .

git commit -m %1

git push origin
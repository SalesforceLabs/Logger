ios:
	cake --config ios.json dev

android:
	cake --config android.json dev

nodejs:
	mkdir -p public
	rsync -r src/images/ public/images/
	rsync libs/client/*.js public/javascripts/
	node-dev app.coffee

tdd:
	@NODE_ENV=test ./node_modules/.bin/mocha -b -G -w \
	--compilers coffee:coffee-script \
	--reporter dot

casper:
	casperjs test/casper/test.coffee

docs:
	rm -fr docs
	./node_modules/.bin/docco src/coffeescripts/*.coffee

lint:
	coffeelint -f test/config/coffeelint.json src/coffeescripts/*.coffee

clean:
	rm -rf public/
	rm -rf docs/

pull:
	git pull origin dev
	
push:
	git push origin dev

dev2stable:
	git checkout stable
	git merge dev
	git push origin stable
	git checkout dev

stable2master:
	git checkout master
	git merge stable
	git push origin master
	git checkout dev

deploy:
	git push heroku refs/remotes/github/master:refs/heads/master

test:
	@NODE_ENV=test ./node_modules/.bin/mocha -b -G \
	--compilers coffee:coffee-script \
	--reporter xunit > xunit.xml

.PHONY: test docs ios android

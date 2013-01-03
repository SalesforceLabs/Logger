# Logger by Salesforce Labs

Logger is a cross-platform (iOS/Android) mobile app to log sales activities and notes. Logger is a [Cordova](http://cordova.apache.org/) hyrbrid app build on top of the [Salesforce Mobile SDK](http://wiki.developerforce.com/page/Mobile_SDK) for [iOS](https://github.com/forcedotcom/SalesforceMobileSDK-iOS) and [Android](https://github.com/forcedotcom/SalesforceMobileSDK-Android).

Install the app for [iOS](http://bit.ly/LoggeriOS) or. [Android](http://bit.ly/LoggerAndroid).  
Follow on [Twitter](https://twitter.com/saleslogger).

## Setup

In order to build Logger you need [NodeJS](http://nodejs.org) version >=0.8 and [CoffeeScript](http://coffeescript.org). All other dependencies are install with NPM:

    $ sudo npm install -g coffee-script
    $ git clone git@github.com:ForceDotComLabs/Logger.git
    $ cd Logger
    $ npm install .

To test Logger as a NodeJS web app you also need [Redis](http://redis.io/) and [node-dev](https://github.com/fgnass/node-dev).

    $ brew install redis
    $ sudo npm install -g node-dev


## OAuth
### Hybrid App
Create a new Connected App:
- Setup
- App Setup -> Create -> Apps
- Connected Apps -> New
- Enter all required information
- Specify `loggr:///login/success/redirect` as the __Callback URL__.

If you want a different Callback URL you can edit `src/coffeescript/ContainerAuth.coffee`. It is best practice to not include the Consumer Key in the source code. Therefor you have to declare an environment variable. If you use bash edit your ``/.bash_profile` and export the Client Id:

    export LOGGER_CLIENT_ID=<Your OAuth Consumer Consumer Key>

### Web App
To run the web app you need to create another OAuth consumer with the Callback Url `http://localhost:4000/token` and also export the Consumer Key and Consumer Secret:

    export LOGGER_WEB_CONSUMER_KEY=<Your OAuth Consumer Consumer Key>
    export LOGGER_WEB_CONSUMER_SECRET=<Your OAuth Consumer Consumer Secret>
The variables are used in `routes/index.coffee`.

## Build Targets

To build the hybrid app open the terminal and call `make` with the corresponding target. The process adds watchers to the filesystem which re-compiles CoffeeScript, Stylus and the templates whenever a change is detected.

### iOS

    $ make ios

Open `xcode/Logger.xcodeproj` with XCode. Select your device or the simulator and run it with `Cmd+r`. Whenever you change source code you only have to re-run the app again to see the changes. When you are done developing kill the `make ios` process.

### Android

    $ make android

Open Eclipse and
- Import the `android` project.  
- Import the [Salesforce Mobile SDK Android](https://github.com/forcedotcom/SalesforceMobileSDK-Android) `SalesforceMobileSDK-Android/native/SalesforceSDK`
- Open Logger project settings, switch to Android and add the Mobile SDK as a library
- Clean project
- Right-click Loggr in the Project Explorer and select _Debug As_ -> _Android Application_.

Whenever you change source code you only have to switch to Eclipse, select the project, hit F5 and re-run the app. When you are done developing kill the `make android` process.

### NodeJS Web App
To test the web app you need to run Redis and NodeJS express server:

    $ redis-server & make nodejs

Open browser and point to [localhost:4000](http://localhost:4000) and login with your Salesforce credentials. To enable cross-domain request we recommend to use [Google Chrome Canary](https://tools.google.com/dlpage/chromesxs/) and disable the web security with the following script:


    #!/bin/bash
    open -a /Applications/Google\ Chrome\ Canary.app --args --allow-file-access-from-files --disable-web-security

Chrome Canary also supports to emulate a mobile browser with Touch events and specific device metrics like 320x480.

__IMPORTANT__: Only use this browser instance for testing since web security is disabled!

## Development

All source files live in the `src` directory.

### Scripting

Scripting is implemented using [CoffeeScript](http://coffeescript.org).  
The main entrypoint is `src/coffeescripts/Main.coffee`.

### Styling

Styling is implemented using [Stylus](http://learnboost.github.com/stylus/).  
`src/stylesheets/main.styl` contains the main stylesheets and `src/stylesheets/mixins.styl` contains the mixin-functions.

### Templates

[Hogan.js](http://twitter.github.com/hogan.js/) is used as the template engine.  
The main site templates are in `src/views` and all others are in `src/templates`.

### NodeJS

For the NodeJS portion please have a look at `app.coffee` and `routes/index.coffee`.

## Tests

### Unit Tests

Unit tests are build on top of [Mocha](http://visionmedia.github.com/mocha/) and [should](https://github.com/visionmedia/should.js).

    $ make tdd

With this command all tests are executed whenever a file changes. We recommend to have [Growl](http://growl.info/) installed so you get notifications whenever tests are failing.

### Functional Tests

The [CasperJS](http://casperjs.org/) tests are still experimental and work in progress.

    $ brew install casperjs
    $ make casper

In order to run the tests you need to specify environment variables for the test user:

    export LOGGER_TEST_USER=<test user username>
    export LOGGER_TEST_PASS=<test user password>

The tests run a headless browser and take screenshots which can be found in the `temp` directory.

## Lint

CoffeeLint is used as CoffeeScript linting engine.  
Config file: `test/config/coffeelint.coffee`  
Run it with:

    $ make lint

Right now you see lots of errors for `Line ends with trailing whitespace`. This is caused by the way we document the code using docco and there is an [enhancement request file](https://github.com/clutchski/coffeelint/issues/45).

## Docs

Docs are generated using [docco](http://jashkenas.github.com/docco/) and [Pygments](http://pygments.org).

    sudo easy_install Pygments
    make docs

Open the docs folder and find the source code documentation for each class.

## License

Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
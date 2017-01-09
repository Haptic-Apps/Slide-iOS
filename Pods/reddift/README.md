[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](http://img.shields.io/cocoapods/v/reddift.svg?style=flat)](http://cocoadocs.org/docsets/reddift)
[![License](https://img.shields.io/cocoapods/l/reddift.svg?style=flat)](http://cocoadocs.org/docsets/reddift)
[![Platform](https://img.shields.io/cocoapods/p/reddift.svg?style=flat)](http://cocoadocs.org/docsets/reddift)

# reddift
reddift is Swift Reddit API Wrapper.

 * Supports OAuth2(is not supported on tvOS currently).
 * Supports multi-accounts.
 * Includes a sample application(iOS only).

## Sample on iOS
![sc02](https://cloud.githubusercontent.com/assets/33768/7570674/e68381c0-f84c-11e4-914b-532f9fd06e19.png)　
![sc01](https://cloud.githubusercontent.com/assets/33768/7570673/e653f39c-f84c-11e4-98c7-2c3e9ef872ad.png)

## Sample on tvOS
![simulator screen shot 2015 11 18 14 48 05](https://cloud.githubusercontent.com/assets/33768/11233653/71979ba6-8e03-11e5-9ca5-077bcf2abfa5.png)

## Document

* See [cocoapods](http://cocoadocs.org/docsets/reddift/).
* [List of not implemented APIs](https://github.com/sonsongithub/reddift/wiki/Not-implemented-APIs)

## How to build

Now, it's under developing.
You have to pay attention to use this library.

#### 1. Check out source code.

```
# check out reddift and its submodules.
> git clone --recursive https://github.com/sonsongithub/reddift.git
```

#### 2. Create application(installed app) at reddit.com

Create new installed app via preference page at reddit.com.
And then, check your app's ```cliend_id``` and fill out ```redirect_uri``` for OAuth2.
For example, ```redirect_uri``` is set to ```myapp://response```.
In following sample, ```redirect_uri``` is set to ```reddift://response```.

![installedapp](https://cloud.githubusercontent.com/assets/33768/7569703/7aa0cd84-f845-11e4-8860-2c953c9522a2.png)


#### 3. Set up ````reddift_config.json````

This JSON file saves application information to use OAuth.
Rename ```reddift_config.json.sample``` to ```reddift_config.json```.
And fill out ```DeveloperName```, ```redirect_uri``` and ```client_id```.
```redirect_uri``` must be same one you registered at reddit.com.
You can check ```client_id``` at application tab.
reddift generates http's user-agent property using this JSON and application's info.plist.

    {
      "DeveloperName": "<YOUR NAME>",
      "redirect_uri": "<YOUR REDIRECT URI>",
      "client_id": "<YOUR ID>"
    }

#### 4. Set up your URI on Xcode

In Xcode, set up URL Types in order to receive call back from Safari.
Set ```URL Schemes``` to ```redirect_uri``` that you set at reddit.com. 
You don't have to include ```://response``` to this form.
These URI must be identical.
If they are not identical, reddit.com does not authorize your OAuth request.
In following sample, ```URL Schemes``` is set to ```reddift```.

![reddit2](https://cloud.githubusercontent.com/assets/33768/7277677/52a1d1f0-e94c-11e4-9125-18c3acf13c0b.png)

## How to build test

#### 1. Register user script app

Test uses Application Only OAuth to remove user interaction from test process.
If you want to run tests of reddift, you have to create another "Script" type application(personal use script) at reddit.com.

![userscript](https://cloud.githubusercontent.com/assets/33768/7569704/7ad7bf10-f845-11e4-8e10-89487a65d5d4.png)

#### 2. Fill out ````test_config.json````

At first, rename ````test_config.json.sample```` to ````test_config.json````.
Fill each following value using above preference pain of reddit.com.

    {
      "username": "test user account",
      "password": "test user password",
      "client_id": "test app client ID(must be script type app)",
      "secret": "test app secret"
    }

#### 3. Start test

Cmd + U.

## Create you app.

#### Get something & Error handling

reddift returns ```Result<T>``` object as a result.
Get the value or error from ```Result<T>``` object.
Concretely, you can access either value evaluating enum state like a following code.


    // do not use "!" in your code
    switch(result) {
    case .Failure(let error):
        println(error)
    case .Success(let listing):
        // do something to listing
    }

In more detail about this coding style, see "[Efficient JSON in Swift with Functional Concepts and Generics](https://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics)".

#### Create session

At first, you have to implement codes to receive the response of OAuth2 in ```UIAppDelegate```.
reddift let you save tokens as a specified name into KeyChain.
Specifically, following sample code saves token as user name at reddit.com.

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return OAuth2Authorizer.sharedInstance.receiveRedirect(url, completion:{(result) -> Void in
            switch result {
            case .Failure(let error):
                print(error)
            case .Success(let token):
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    OAuth2TokenRepository.saveIntoKeychainToken(token, name:token.name)
                })
            }
        })
    }

To communicate with reddit.com via OAuth2, you have to create ```Session``` object.
See following section about getting response or error handling.

	let result = OAuth2TokenRepository.restoreFromKeychainWithName(name)
	switch result {
	case .Failure(let error):
	    print(error.description)
	case .Success(let token):
	    con.session = Session(token: token)
	}

You can get contents from reddit via ```Session``` object like following codes.

    session?.getList(paginator, subreddit:subreddit, sort:sortTypes[seg.selectedSegmentIndex], timeFilterWithin:.All, completion: { (result) in
        switch result {
        case .Failure(let error):
            print(error)
        case .Success(let listing):
            self.links.appendContentsOf(listing.children.flatMap{$0 as? Link})
        }
    })

#### Use Application Only OAuth

You can use ```OAuth2AppOnlyToken``` when you want to write a code for test or personal script tool(such as CLI).
```OAuth2AppOnlyToken``` enabled to access reddit without human action in order to authorize in web browser apps.
Do not use ```Oauth2AppOnlyToken``` in installed app in terms of security.

    OAuth2AppOnlyToken.getOAuth2AppOnlyToken(
        username: username,
        password: password,
        clientID: clientID,
        secret: secret,
        completion:( { (result) -> Void in
        switch result {
        case .Failure(let error):
            print(error)
        case .Success(let token):
            self.session = Session(token: token)
        }
    }))

#### Further more,

In more detail, See my sample application, test code or Playground code included in this repository.

## Playground

You can play with reddift in Playground.
In more detail, check reddift.playground package.
Before using, you have to copy ```test_config.json``` into ```./reddift.playground/Resources``` in order to specify user account and your application informatin because reddift on Playground uses "Application Only OAuth".

![playground](https://cloud.githubusercontent.com/assets/33768/9929315/deb40d78-5d66-11e5-908f-0445ad57ef90.png)

## Dependency

* reddift depends on [MiniKeychain](https://github.com/sonsongithub/MiniKeychain) for saving access tokens.
* Sample application depends on [UZTextView](https://github.com/sonsongithub/UZTextView.git).

## License

MIT License.

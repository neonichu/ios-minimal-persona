# Mozilla Persona on iOS

This project demonstrates how to login into a website using [Persona][1]
in an iOS app. This can be used for authentication for an API, for example.
The sample app will log into [sloblog.io][2], which uses 
[omniauth-browserid][3]. The code has only been tested with this site and
should be considered awesome, yet experimental.

## Using it for your own project

You will need all the files with prefix *BrowserID* in your project.
Make sure the JS is added as a resource and not as source code. Set
the parameters of *BrowserIDViewController* to match those of the
site you want to access. You will get one or more *NSHTTPCookies* back
which you can use to make subsequent authenticated requests.

[1]: https://developer.mozilla.org/en-US/docs/persona
[2]: http://sloblog.io
[3]: https://github.com/intridea/omniauth-browserid

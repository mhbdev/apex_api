## 2.0.7

* Major updates on ReactiveWidget

## 2.0.6

* LoginBuilder's State can be maintained using a ValueNotifier being passed as `controller`
* ReactiveWidget State can be also maintained using a stream controller being passed to the
  constructor. `streamController` but make sure to close the stream in your dispose method like
  this:
  ```if (!_controller.isClosed) _controller.close();```

## 2.0.5

* Added storageUniqueKey property to involve another parameter in save_local option

## 2.0.3

* Progress Dialog issue is solved
* Solved send method onError and onComplete problems

## 2.0.0

* Breaking Changes

- ServerWrapper turned into ApiWrapper
- Api class has been removed
- context.api.request => context.http.post

## 1.1.6

* HandlerNamespace is used to route users to different handlers of one api (implemented in ApiConfig
  class)

## 1.1.4

* Fixing wrapper property making it work even if Stream initial data is null

## 1.1.3

* wrapper property now supports response and onRetry method

## 1.1.2

* Added wrapper widget builder to ReactiveWidget

## 1.1.1

ReactiveWidget reload function now returns a future

## 1.1.0

Break Changes

* Response class is removed
* You can extend your Response models from DataModel class

## 1.0.1+5

* OnRetry
* LoginBuilder
* Base64 encoding of http requests.
* ReactiveWidget

## 1.0.1

* Much more stable.
* Some minor bugs has been fixed.

## 1.0.0

* Initial Release
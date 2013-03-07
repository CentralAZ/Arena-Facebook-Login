# CentralAZ Facbook Authentication for Arena ChMS

This set of Arena modules enables a user to authenticate in Arena using their Facebook account.

## Getting started

Clone the repository into your working Arena directory, or download the zip or tarball and unzip it into your working Arena web directory. The wiki on Redmine has [some helpful information](http://redmine.refreshcache.com/projects/cccev-web-collection/wiki/Login_Modules) on how this functionality lays out.

### Dependencies

This module set does have an external dependency on the [Facebook C# API in NuGet version ~5.2.*](http://nuget.org/packages/Facebook/5.2.1.0). Please note that this is an older version. Installing the latest (6.1.*) might require some refactoring to get it to work properly. This can be installed via the NuGet Package Manager that comes integrated with Visual Studio.

The web service and module code files also reference a couple additional dependencies on Central's `FrameworkUtils` and `DataUtils` projects. `FrameworkUtils` has a dependency on `DataUtils`. The source code for those projects can be found here:

* [DataUtils](http://redmine.refreshcache.com/projects/cccevdatautils/repository)
* [FrameworkUtils](http://redmine.refreshcache.com/projects/cccevframeworkutils/repository)

### Modifying the client source code & running tests

The client side code is all written in [CoffeeScript](http://coffeescript.org). If you need to build it, you'll want to install [Node](http://nodejs.org/) and run `npm install -g coffee-script` to install the CoffeeScript compiler. You can then `cd` into the `usercontrols/custom/cccev/web` folder and run `coffee -j scripts/centralaz.facebook.js -c coffeescripts/lib/facebook/`. Alternatively in Windows, you can try using the [Mindscape Web Workbench](http://www.mindscapehq.com/products/web-workbench) plugin for Visual Studio.

The CoffeeScript source files are located in `usercontrols/custom/cccev/web/coffeescripts/lib`. There are unit tests written in Jasmine that can be executed via the test runner located in `usercontrols/custom/cccev/web/spec/run/SpecRunner.html`. The spec source is also written in CoffeeScript found at `usercontrols/custom/cccev/web/coffeescripts/spec/lib/facebook`.
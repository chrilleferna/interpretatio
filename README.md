# Interpretatio

Keeping track of translation files for several languages is a challenge. If you're on a project that delivers continuous updates
you need to update all language files before deploying, and in many cases you will need help with some of the translations.
Knowing what needs to be done is difficult and getting all the parts together even more so. I initially built a database-centered
Rails application to handle translations. This worked fine, but had performance penalties when the translation records grew large
(you would want to be able to move around quickly, almost like using a text editor) and involves quite some book-keeping with
exports and moving files around.

Interpretatio is a light-weight solution to providing a Web interface for translators that can be built into your Rails
application, and that works directly on the translation files. It is a Rails Engine (i.e. a Gem adding controllers and views to
your application) that you can use either in the development environment, on a staging server where translators log in and
update the translation records, or even (possibly) on a production server to make quick fixes. I often use it in the development
environment, since it provides superior organization of the translation records, as compared to editing a bunch of YAML files.

## Requirements

Interpretatio is compatible with Rails 4 (if you try it on other version of Rails, please let me know).

## Installation and Initial setup

#### 1) Include the gem

Put

````
gem "interpretatio"
````

in your application's Gem file and run bundle install.

#### 2) Generate configuration

In your application's root directory do:

````
rails generate interpretatio
````

This will generate an initialization file config/initializers/interpretatio.rb that **you must consult and most certainly modify**.
The changes to that file, and possibly to your I18.rb or localization.rb initializer will be described below, after explaining
the various options.

#### 3) Mount the Interpretatio Engine

In your application's config/routes.rb file you need to "mount" the Interpretario engine on a suitable path, by adding a line
like this:

````
  mount Interpretatio::Engine => "/interpretatio"
````

#### 4) Select target languages

At a minimum you need to specify the localizations (languages) you want to support in the file config/initializers/interpretatio.rb.
For further changes, see next section.


## Setting up your configuration for localization files

In order to configure how Interpretatio will handle the localization files, you need a basic understanding how I18n handles these. 

YAML is the most common format for localization records and this format is quite readable also for humans; hoowever, I18n also
supports the Ruby Hash format, which is much more efficient to process when reading from and writing to files. This is
therefore the format natively used by Interpretatio, which works in such a way that every update to a localization record is
immediately reflected in Interpretatio's hash file.

You may decide if you would like I18n to work on this file directly
(meaning that every change is immediately visible in your applcation), or if you prefer I18n to continue working with the YAML
format, in which case you need to export data from Interpretatio to the YAML file(s) when you want changes to be seen. Although
not necessarily the "best" organization, this is the way Interpretatio is configured by default, since it does not involve any
changes to your current I18n configuration.

In order to avoid clashes when I18n reads the localization files, Interpretatio stores things in different
directories:

* YAML_DIRECTORY. This is where the localization files in the Yaml format are stored. The I18n default is to use config/locales.
This is also the default set-up for Interpretatio

* HASH_DIRECTORY. This is where Interpretatio stores the Ruby hash file, which is updated every time a localization is changed.
The Interpretatio default is: config/locales/HASH

* BACKUP_DIRECTORY. Every time the Interpretatio user exports to Yaml files, a bunch of backup files is also automatically created
in this directory, one for each Yaml file created and one for the Ruby hash file.
The Interpretatio default is: config/locales/BACKUP. Interpretatio uses a rolling backup scheme and in the configuration you 
may set the number of backups to keep. The default is 3.

## When using Interpretatio outside the development environment

If you use Interpretatio on a shared staging server or in production it is important to notice that **every new deployment will
overwrite the files in config/locales**. This means that if you're not careful, any changes created on these servers will
be wiped out and lost (more or less). For this reason, if you want to use Interpretatio this way you need to store the
localization files in a location which is maintained across deployments. If you use Capistrano for deployment, a safe place to
use is within public/system. Consult the config/initializers/interpretatio.rb file to see how you easily can configure
Interpretatio to use that location.

If you would like I18n to also look for localization files in public/systems (which you most certainly want), you need to add
the following information in your application's I18n configuration file (which you need to create if it does not exist, using
a filename such as I18n.rb or localization.rb and store it in config/initializers):

````
I18n.load_path += Dir[Rails.root.join('public', 'system', 'locales', '*.{rb,yml}')]
````


## Use

Once you have made the desired changes to config/initializers/interpretatio.rb you need to restart your Rails server. If you
run in a development environment, Interpretatio will print out some configuration information on the console. Go to your
application and add the path that you put in the routes.rb file (see step 2 above). The first time you do that you will most
certainly end up in with a "Fix configuration issues" message, until all things are in place and any original Yaml files have
been imported (assuming you're starting to use Interpretatio on an existing application, which already have a bunch of Yaml
files). Just follow the guidance and once all has been fixed, the use should be quite obvious.

## Authorization

If you would like to restrict the use of Interpretatio, a hook is provided
to a before\_action filter in its controller, allowing you to define an `interpretatio_athorization` action 
in your application's ApplicationController, for example:

```ruby
def interpretatio_authorization
  unless user_signed_in?
    flash[:error] = "You need to sign in first"
    redirect_to main_app.root_url
  end
end
```

## Styling

All of Interpretatio's styles can be overridden in a (S)CSS file in your application, nesting your rules within `html.interpretatio`.


This project rocks and uses MIT-LICENSE.

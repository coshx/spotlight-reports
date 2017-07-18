# Spotlight Reports

Spotlight Reports is a tool provider for Instructure's [Canvas](https://github.com/instructure/canvas-lms) Learning Mangagement System.

It offers a way to view stats about the instructors within a sub-account.

## Deployment

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

1. Generate an API Token from Canvas
    a. Go to your canvas installation, navigate to Account -> Settings (`/profile/settings`) and add a **New Access Token**
    a. Copy the access token that's generated. This will be your `API_TOKEN`.
1. Use the button above to deploy Spotlight Reports to Heroku.
    a. For the environment variables, you can make up strings for `OAUTH_KEY` and `OAUTH_SECRET`. 
1. Add Spotlight Reports to your Canvas installation
    a. Switch to Admin View in canvas if you're not already there
    a. Navigate to Admin -> _Main Account_ -> Settings (`/accounts/1/settings`)
    a. Go to the `Apps` tab
    a. Add a New App
    a. Under `Configuration Type`, select `By URL`
    a. Type _Spotlight Reports_ for the Name
    a. Enter the `OAUTH_KEY` and `OAUTH_SECRET` you made up previously for the _Consumer Key_ and _Shared Secret_, resepectively
    a. For the `Config URL`, enter `http://my-app.herokuapp.com/tool_config.xml` (replacying my-app with the name of your heroku instance).
1. To keep the data up-to-date, add a nightly data import
    a. Go to https://heroku.com/apps
    a. Select the app you created
    a. Go to **Resources**
    a. Select the **Scheduler** app
    a. Schedule a task to run each night with the command `bundle exec rake update_database` - this is the nightly database update. Feel free to schedule more or less frequently.

## Development

### Step 1
To work on this project you will need an instance of Canvas running and API access to that instance. 
* [View the repo for instructions on running Canvas.](https://github.com/instructure/canvas-lms)
* [How do I obtain an API access token?](http://guides.instructure.com/m/4214/l/40399-how-do-i-obtain-an-api-access-token)

### Step 2
Clone this repo and set up your credentials. To do so, create a file called `canvas.yml` in the `/config` folder. It should contain the following:

```
development:
  OAUTH_KEY: <generate one of these yourself>
  OAUTH_SECRET: <generate one of these yourself>
  API_URL: <this is the link to your canvas instance API>
  API_TOKEN: <this is the token you got when you set up API access>
production:
  OAUTH_KEY:
  OAUTH_SECRET: 
  API_URL: 
  API_TOKEN: 
```

### Step 3
Start the app. 
```
bundle install
rake db:create
rake db:migrate
rails s
```

### Step 4
Install the app add-on into your Canvas instance. 

**Note:** If your Canvas instance is not running locally, you will need to expose the port on which you are running Spotlight Reports to the internet. [ngrok](https://ngrok.com/) is a good solution for this.

In your Canvas instance do the following:
* Go to your Managed Accounts
* Click Settings in the left-hand nav
* Click the Apps tab
* Click View App Configurations
* Click Add App
* In the Configuration Type drop down, select "By URL"
* Type in the name: Spotlight Reports
* Paste in the Consumer key and Shared Secret that you created for canvas.yml
* Paste the URL for the Configuration XML. For example: "https://localhost:3000/tool_config.xml" or "https://******.ngrok.com/tool_config.xml"
* Click Submit

You should be told the app was successfully added. Refresh the page again and you will see "Spotlight Reports" added to the left-hand nav.

### Step 5
Populate your database
```
rake populate_database
```

Once all those steps are done, you should be able to go to a sub-account, click Spotlight Reports, and see a list of teachers with published courses.


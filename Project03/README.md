# Project 03

A social media app inspired by reddit, containing a client-side app written with Elm and a server-side app written with Django.

# Setup on Mac1XA3 Server

NOTE: You MUST have Elm, Python3 and Git installed to follow these instructions.

First, clone the repo using `git clone https://github.com/JohnWinter13/CS1XA3.git`

## Server-side Setup

1. Create a python virtual enviroment using `python -m venv ./python_env`

2. Activate the virtual enviroment `source python_env/bin/activate` NOTE: syntax varies depending on the operating system you are using. Consult https://virtualenv.pypa.io/en/stable/userguide/ if you are having trouble.

3. Install required packages using `pip install -r CS1XA3/Project03/requirements.txt`

4. Change directory into the django_project using `cd Project03/django_project/`

5. Using your favorite text-editor, edit `django_project/urls.py` and change the value of the variable `root` to `e/macid`

6. Run the server using `python manage.py runserver localhost:port` where port is your assigned student port.

## Client-side Setup

1. Change directory to `elm_project/src`
2. Edit `Main.elm` so that the constant `rootUrl` equals to `https://mac1xa3.ca/e/macid/`
3. Run `elm make src/Main.elm` to generate an HTML file of the client-cide code.
4. Copy the HTML file into your `public_html` directory.
5. You will now be able to access the app at `https://mac1xa3.ca/u/macid/` 

# Features

## Server-side

1. Several apps containing methods that communicate via Http Post and Http Get, accepting and/or returning JSON.
2. A userauth app supporting user registration, login and logout.
3. A threads app supporting thread and subreddit creation.
4. Usage of custom model classes to model threads and subreddits.
5. Threads belong to a subreddit and can also have a parent thread (i.e. posts can have a reply) through usage of many-to-one relationships.

## Client-side

1. An elm application which communicates to the django server application using Http Post and Http Get, where appropriate.
2. Various JSON Encoders and Decoders written to map JSON to a combination of different data types, including lists, custom algebraic data types and the Maybe type.
3. Utilized maps, filters, etc to allow user to perform multiple features, such as filter content and view posts only belonging to the subreddit they are browsing.
4. Usage of several HTML events and attributes.
5. Usage of Bootstrap and FontAwesome for styling, with a little bit of custom CSS. (Some CSS was also borrowed from https://startbootstrap.com/snippets/login/).
6. https://package.elm-lang.org/packages/EdutainmentLIVE/elm-dropdown/latest/ was used to aid with managing dropdown menu state.

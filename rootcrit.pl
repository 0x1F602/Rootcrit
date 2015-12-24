#!/usr/bin/env perl
use Mojolicious::Lite;

my $verbose_debug = 2;
my $no_debug = 0;
my $debug_level = $no_debug;

plugin 'Authentication' => {
  'autoload_user' => 1,
  'session_key' => 'rootcritbro', # CHANGE ME
  'load_user' => sub {
    my ($c, $uid) = @_;
    my $config = $c->app->plugin('Config');
    my $user = $config->{username};
    return $user;
  },
  'validate_user' => sub {
    my ($c, $username, $password, $extradata) = @_;
    my $uid = 0;
    my $config = $c->app->plugin('Config');
    my $good_username = $config->{username} // 'insecure';
    my $good_password = $config->{password} // 'password';
    if ($username eq $good_username && $password eq $good_password) {
       $uid = 1;
    }
    return $uid;
  },
  'current_user_fn' => 'user', # compatibility with old code
};

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

plugin 'Config';
 
any '/login' => sub {
    my $c = shift;

    my $u = $c->req->param('username');
    my $p = $c->req->param('password');
 
    if ($c->authenticate($u,$p)) {
      $c->redirect_to('/');
    }
    else {
      $c->render(
        template => 'login',
        message => 'Failed to login'
      );
    }
};

get '/logout' => (authenticated => 1) => sub {
    my $self = shift;
 
    $self->logout();
    $self->render( template => 'login', message => 'Logged out...' );
};

get '/' => sub {
  my $c = shift;
  if (!$c->is_user_authenticated) {
    $c->render(
      template => 'login',
      message => 'You were not authenticated',
    );
  }
  else {
    $c->render(
      template  => 'index',
      uptime    => 'Loading',
      who       => 'Loading',
      top       => 'Loading',
      motion    => 'Loading',
    );
  }
};

get '/info/uptime' => (authenticated => 1) => sub {
    my $c = shift;
    my $uptime = qx(uptime);
    $c->render(
      json => $uptime,
    );
};

get '/info/who' => (authenticated => 1) => sub {
    my $c = shift;
    my $who = qx(who);
    $c->render(
      json => $who,
    );
};

get '/info/top' => (authenticated => 1) => sub {
    my $c = shift;
    my $top = qx(top -n 1 -b);
    $c->render(
      json => $top,
    );
};

get '/info/motion' => (authenticated => 1) => sub {
    my $c = shift;
    my $motion_status = qx(ps aux | grep motion);
    $c->render(
        json => $motion_status, 
    );
};

get '/shutdown' => (authenticated => 1) => sub {
  my $c = shift;
  qx(shutdown -h now);
  $c->render(template => 'shutdown');
};

get '/motion/start' => (authenticated => 1) => sub {
    my $c = shift;
    my $config = $c->app->plugin('Config');
    my $config_path = $config->{motion_config_path};
    my $motion_command = 'motion';
    if ($config_path) {
        $motion_command .= " -c $config_path";
    }
    system "$motion_command &";
    $c->render(
        template => 'index',
        uptime    => 'Loading',
        who       => 'Loading',
        top       => 'Loading',
        motion    => 'Loading',
    );
};

get '/motion/stop' => (authenticated => 1) => sub {
    my $c = shift;
    system 'killall motion';
    $c->render(
        template => 'index',
        uptime    => 'Loading',
        who       => 'Loading',
        top       => 'Loading',
        motion    => 'Loading',
    );
};

# Index page
    # Collect some system information for the user
    # Show the shutdown switch
# Accept a shutdown command
    # Create a calendar event for remote shutdown event
    # Shut down the system properly
    
app->start;
__DATA__

@@ index.html.ep
    % content_for css => begin
        div.rootcrit-top pre {
            height: 400px;
            overflow: auto;
        }
        .top-level-spacing {
            margin-bottom: 50px;
        }
    % end
    % content_for javascript => begin 
        $(document).ready(function () {
            var debug = 0;
            var host_system_information = ['uptime', 'who', 'top', 'motion'];
            var update_function = function () {
                if (debug) {
                  console.log(host_system_information.length);
                }
                for (var i = 0; i < host_system_information.length; i++) {
                  var host_command = host_system_information[i];
                  var host_update_container = 'div.rootcrit-' + host_command + ' .update-container';
                  if (debug) {
                    console.log('host system information ' + i);
                    console.log(host_update_container);
                    console.log('Starting ajax');
                  }
                  var update_ajax = function (host_command, host_update_container) {
                    $.ajax({
                      url: '/info/' + host_command,
                      success: function (return_data) {
                          if (debug) {
                            console.log('host_command ' + host_command);
                            console.log('host_update_container ' + host_update_container);
                          }
                          $(host_update_container).text(return_data);
                      },
                      error: function (jqXHR, textStatus, errorThrown) {
                          $(host_update_container).text(textStatus + ' ' + errorThrown);
                      }
                    });
                  };
                  update_ajax(host_command, host_update_container);
                }
            };
            update_function();
            var update_timer = setInterval(update_function, 2000);

            var motion_status_function  = function () {
                if (debug) {
                    console.log('Inside motion function');
                }
                // basically we are going to check '/info/motion/status' and
                // we will get a json response  telling us if it's up or down
                // we take that status and toggle the button on/off based on
                // that result
            };
            // and put a timer here for the motion status function

            // we can embed the mjpeg stream from motion here if we have it
            // chrome and safari should refresh automatically...allegedly

            // we want a gallery of the backlogged motion events
            // but I am not sure what the interface should look like right now.
            // obviously we prioritize new events over old events. but if you are
            // looking at a single event, we don't want to change focus or make it harder
            // to look back in time.

            // I should look into some real time events. It might behoove me to a reddit front-page like
            // setup where it's a list on its own page that needs to be refreshed manually
            // individual events should have their own page and should be linkable based on UUID

            $('div#shutdown-button > form').click(function (e) {
                if (confirm('Are you sure?')) {
                    return;
                }
                e.preventDefault();
            });
        });
    % end
% layout 'default';
% title 'Rootcrit';
<div class='panel'>
  <div class='col-xs-12 col-sm-6 col-sm-offset-3 top-level-spacing'>
    <h1>Welcome to Rootcrit</h1>
  </div>
  <div id='shutdown-button' class='col-xs-12 col-sm-6 col-sm-offset-3 top-level-spacing'>
    <form action="/shutdown">
      <button class='btn btn-primary col-xs-12'>Shutdown the system</button>
    </form>
  </div>
  <div class="col-xs-12 col-sm-6 col-sm-offset-3 top-level-spacing">
    <button class="btn btn-primary col-xs-12" type="button" data-toggle="collapse" data-target="#rootcrit-system-info" aria-expanded="false" aria-controls="rootcrit-system-info">
        Show/hide system info 
    </button>
    <div id="rootcrit-system-info" class="collapse">
        <div class='rootcrit-uptime col-xs-12'>
          <h2>uptime</h2>
          <pre class="update-container">
    <  %= $uptime %>
          </pre>
        </div>
        <div class='rootcrit-who col-xs-12'>
          <h2>who</h2>
          <pre class="update-container">
    <  %= $who %>
          </pre>
        </div>
        <div class='rootcrit-top col-xs-12'>
          <h2>top</h2>
          <pre class="update-container">
    <  %= $top %>
          </pre>
        </div>
        <button class="btn btn-primary col-xs-12" type="button" data-toggle="collapse" data-target="#rootcrit-system-info" aria-expanded="false" aria-controls="rootcrit-system-info">
            Show/hide system info
        </button>
    </div>
  </div>
  <div class='rootcrit-motion col-xs-12 col-sm-6 col-sm-offset-3 top-level-spacing'>
    <h2>motion</h2>
    <a href="/motion/start" style="padding-bottom: 20px">
        <button class='btn btn-primary col-xs-12 top-level-spacing'>Start motion</button>
    </a>
    <a href="/motion/stop">
        <button class='btn btn-primary col-xs-12 top-level-spacing'>Stop motion</button>
    </a>
    <pre class="update-container">
<%= $motion %>
    </pre>
  </div>
  <div class='col-xs-12 col-sm-6 col-sm-offset-3 top-level-spacing'>
    <a href="/logout">
      <button class='btn btn-primary col-xs-12'>Logout</button>
    </a>
  </div>
</div>

@@ login.html.ep
% layout 'default';
% title 'Rootcrit - Login';
<div class="panel">
    <div class="col-xs-12 col-sm-4 col-sm-offset-4">
        <h2><%= $message %></h2>
    </div>
    <div class="col-xs-12 col-sm-4 col-sm-offset-4">
        <form method="POST" action="/login">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" name="username"></input>
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" name="password"></input>
            </div>
            <button type="submit" class="btn btn-default">Submit</button>
        </form>
    </div>
</div>

@@ shutdown.html.ep
% layout 'default';
% title 'Shutting Down';
<h1>Thanks for playing</h1>

@@ not_found.html.ep
% layout 'default';
% title '404 Not Found';

<h1> 404 Not Found </h1>
<a href="/">Return to Site</a>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="http://code.jquery.com/jquery-2.1.4.min.js"></script>

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" integrity="sha512-dTfge/zgoMYpP7QbHy4gWMEGsbsdZeCXz7irItjcC3sPUFtf0kuFbDz/ixG7ArTxmDjLXDmezHubeNikyKGVyQ==" crossorigin="anonymous">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css" integrity="sha384-aUGj/X2zp5rLCbBxumKTCw2Z50WgIr1vs/PFN4praOTvYXWlVyh2UtNUU0KAUhAX" crossorigin="anonymous">
    <!-- Custom CSS -->
    <style>
        <%== content 'css' %>
    </style>

    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js" integrity="sha512-K1qjQ+NcF2TYO/eI3M6v8EiNYZfA95pQumfvcVrTHtwQVDG+aHRqLi/ETn2uB+1JqwYqVG3LIvdm9lj6imS/pQ==" crossorigin="anonymous"></script>
    <!-- Custom Javascript -->
    <script>
        <%== content 'javascript' %>
    </script>
  </head>
  <body><%= content %></body>
</html>

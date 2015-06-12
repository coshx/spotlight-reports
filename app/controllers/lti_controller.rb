require 'ims/lti'

class LtiController < ApplicationController

  skip_before_filter :verify_authenticity_token

  $oauth_creds = {ENV['OAUTH_KEY'] => ENV['OAUTH_SECRET'], "testing" => "supersecret"}


  def was_nonce_used_in_last_x_minutes?(nonce, minutes=60)
    # some kind of caching solution or something to keep a short-term memory of used nonces
    false
  end

  def show_error(message)
    @message = message
  end

  def authorize!
    if key = params['oauth_consumer_key']
      if secret = $oauth_creds[key]
        @tp = IMS::LTI::ToolProvider.new(key, secret, params)
      else
        @tp = IMS::LTI::ToolProvider.new(nil, nil, params)
        @tp.lti_msg = "Your consumer didn't use a recognized key."
        @tp.lti_errorlog = "You did it wrong!"
        show_error "Consumer key wasn't recognized"
        return false
      end
    else
      show_error "No consumer key"
      return false
    end

    if !@tp.valid_request?(request)
      show_error "The OAuth signature was invalid"
      return false
    end

    if Time.now.utc.to_i - @tp.request_oauth_timestamp.to_i > 60*60
      show_error "Your request is too old."
      return false
    end

    # this isn't actually checking anything like it should, just want people
    # implementing real tools to be aware they need to check the nonce
    if was_nonce_used_in_last_x_minutes?(@tp.request_oauth_nonce, 60)
      show_error "Why are you reusing the nonce?"
      return false
    end

    @username = @tp.username("Dude")

    return true
  end

  def config_xml

    host = request.scheme + "://" + request.host_with_port
    url = (params['signature_proxy_test'] ? host + "/signature_test" : host + "/lti_tool")
    tc = IMS::LTI::ToolConfig.new(:title => "Example Sinatra Tool Provider", :launch_url => url)
    tc.description = "This example LTI Tool Provider supports LIS Outcome pass-back."
    tc.set_ext_params "canvas.instructure.com", {:privacy_level => "public", :domain => "TBD", :text => "Teacher Insight"}

    tc.extend IMS::LTI::Extensions::Canvas::ToolConfig
    tc.canvas_account_navigation!({:enabled => "true"})


    # headers 'Content-Type' => 'text/xml'
    render xml: tc
  end

  def launch_tool
    return render html: "<strong>Not Authorized</strong>".html_safe unless authorize!

    signature = OAuth::Signature.build(request, :consumer_secret => @tp.consumer_secret)

    @signature_base_string = signature.signature_base_string
    @secret = signature.send(:secret)

    school_name = params[:context_title]
    school_id = params[:custom_canvas_account_id]

    session[:school_id] = school_id

    redirect_to root_path(school_name: school_name, school_id: school_id)

  end

end

# Find the build status of project on Jenkins
#
# hubot jenkins jobname - Returns the build status 
#
# Need to be more fault tolerant.
# List jobs
# Display graph images?
# Don't play with colors unless on IRC => Env Var?
# Add conf for using ssl?

colors = 
{
    "blue" : "2,0",
    "red" : "4,0"
    "yellow" : "8,1"
    "default" : "0,1"
};
jenkinsServer = "ci.jenkins-ci.org" #need to import from env var

module.exports = (robot) ->
  robot.respond /jenkins (.*)/i, (msg) ->
    project = escape(msg.match[1])
    msg.http("http://#{jenkinsServer}/job/#{project}/api/json")
      .get() (err, res, body) ->
        response = JSON.parse(body)
        color = colors[response.color] || colors.default
        msg.send "\3#{colors.default}Build status for #{project}: \n\3#{color}" + response.healthReport[0].description + "\3"
        if response.activeConfigurations and response.activeConfigurations.length 
            msg.send "\3#{colors.default}Matrix info :" 
            matrixStatus = []
            for config in response.activeConfigurations
                matrixColor = colors[config.color] || colors.default
                matrixStatus.push "\3#{matrixColor}#{config.name}\3"    
            
            msg.send matrixStatus.join " | "
    

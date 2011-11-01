# Find the build status of project on Jenkins
#
# hubot jenkins jobname - Returns the build status 
#
# hubot jenkins listjobs <statusFilter> - List all job status, possible to filter by failed, success, unstable



# Need to be more fault tolerant.
# List jobs - Add filters
# Authenticate
# Display graph images?
# Don't play with ircColors unless on IRC => Env Var?
# Add conf for using ssl?
# Cache results to redis like a boss?

ircColors = 
{
    "blue" : "2,0",
    "red" : "4,0"
    "yellow" : "8,1"
    "default" : "0,1"
};

jenkins =
{
    server : process.env.JENKINS_SERVER,
    user : process.env.JENKINS_USER,
    password : process.env.JENKINS_PASSWORD,
    ircMode : process.env.JENKINS_IRCMODE || false
}

jobStatusFilters = 
{
    failed : 'red',
    success : 'blue',
    unstable : 'yellow'
}

module.exports = (robot) ->
  robot.respond /jenkins job (.*)/i, (msg) ->
    project = escape(msg.match[1])
    msg.http("#{jenkins.server}/job/#{project}/api/json")
      .get() (err, res, body) ->
        response = JSON.parse(body)
        color = ircColors[response.color] || ircColors.default
        msg.send "\3#{ircColors.default}Build status for #{project}: \n\3#{color}" + response.healthReport[0].description + "\3"
        if response.activeConfigurations and response.activeConfigurations.length 
          msg.send "\3#{ircColors.default}Matrix info :" 
          matrixStatus = []
          for config in response.activeConfigurations
            matrixColor = ircColors[config.color] || ircColors.default
            matrixStatus.push "\3#{matrixColor}#{config.name}\3"    
            
            msg.send matrixStatus.join " | "

  robot.respond /jenkins listjobs(.*)/i, (msg) ->
    filter = escape(msg.match[1])    
    filter = if filter.length > 0 and filter[0..2] is "%20" then filter.substring 3 else filter
    filter = jobStatusFilters[filter] || false
    msg.http("#{jenkins.server}/api/json?tree=jobs[name,color,healthReport[description],lastBuild[number,building,result]]")
      .get() (err, res, body) ->
        response = JSON.parse(body)
        jobsStatus = []
        for job in response.jobs
          if (not filter or job.color is filter)
            color = ircColors[job.color] || ircColors.default
            building =  if job.lastBuild.building then "Currently building.." else "Last build : #{job.lastBuild.number} : #{job.lastBuild.result}"
            jobsStatus.push "\3#{ircColors.default}Project:\3#{color} #{job.name} : #{job.healthReport[0].description} #{building}"
        msg.send jobsStatus.join "\n"


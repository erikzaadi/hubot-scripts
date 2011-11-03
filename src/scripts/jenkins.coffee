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
# Interact with your jenkins CI server, assumes you have a parameterized build
# with the branch to build as a parameter
#
# You need to set the following variables:
#   HUBOT_JENKINS_URL = "http://ci.example.com:8080"
# 
# The following variables are optional
#   HUBOT_JENKINS_JOB - if not set you will have to specify job name every time
#   HUBOT_JENKINS_BRANCH_PARAMETER_NAME - if not set is assumed to be BRANCH_SPECIFIER
#
# build branch master -- starts a build for branch origin/master
# build branch master on job Foo -- starts a build for branch origin/master on job Foo
#module.exports = (robot) ->
#  robot.respond /build\s*(branch\s+)?(\w+\/?\w+)(\s+(on job)?\s*(\w+))?/i, (msg)->
#
#    url = process.env.HUBOT_JENKINS_URL
#
#    job = msg.match[5] || process.env.HUBOT_JENKINS_JOB
#    job_parameter = process.env.HUBOT_JENKINS_BRANCH_PARAMETER_NAME || "BRANCH_SPECIFIER"
#
#    branch = msg.match[2]
#    branch = "origin/#{branch}" unless ~branch.indexOf("/")
#
#    json_val = JSON.stringify {"parameter": [{"name": job_parameter, "value": branch}]}
#    msg.http("#{url}/job/#{job}/build")
#      .query(json: json_val)
#      .post() (err, res, body) ->
#        if err
#          msg.send "Jenkins says: #{err}"
#        else if res.statusCode == 302
#              msg.send "Build started for #{branch}! #{res.headers.location}"
#            else
#              msg.send "Jenkins says: #{body}"

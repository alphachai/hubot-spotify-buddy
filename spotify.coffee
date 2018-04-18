# Description:
#   Spotify hubot helper
#
# Dependencies:
#   none
#
# Configuration:
#   HUBOT_SPOTIFY_CLIENT_ID
#   HUBOT_SPOTIFY_CLIENT_SECRET
#
# Commands:
#   spotify:track:57KhjzSWaiztN8h2AN0MC5
#   https://open.spotify.com/track/57KhjzSWaiztN8h2AN0MC5?si=kpM4BgK9SFqUcyosatLytg
#
# Author:
#   Charlie Mathews <charlie@charliemathews.com> (http://github.com/alphachai)

env = process.env

module.exports = (robot) ->

    handle_err = (res, e, r, b, method, url) ->
        if e
            res.send "Encountered an error #{e}"
            return true
        else if r.statusCode isnt 200
            res.send method + " " + url + " " + r.statusCode
            return true

        false

    describe_track = (res, id, token) ->
        # https://beta.developer.spotify.com/documentation/web-api/reference/tracks/get-track/

        url = "https://api.spotify.com/v1/tracks/" + id
        auth = "Bearer " + token

        robot.http(url)
            .header("Authorization", auth)
            .get() (e, r, b) ->
                if handle_err(res, e, r, b, "GET", url) isnt true
                    try
                        data = JSON.parse b
                    catch
                        res.send "Failed to parse the JSON."

                    artists = null
                    for artist in data.artists
                        if artists
                            artists = artists + ", #{artist.name}"
                        else
                            artists = artist.name

                    cover_art = data.album.images[..].pop()

                    res.send "#{cover_art.url}?.jpg #{data.name} by #{artists}"

    describe_album = (res, id, token) ->
        # https://beta.developer.spotify.com/documentation/web-api/reference/albums/get-album/

        url = "https://api.spotify.com/v1/albums/" + id
        auth = "Bearer " + token

        robot.http(url)
            .header("Authorization", auth)
            .get() (e, r, b) ->
                if handle_err(res, e, r, b, "GET", url) isnt true
                    try
                        data = JSON.parse b
                    catch
                        res.send "Failed to parse the JSON."

                    artists = null
                    for artist in data.artists
                        if artists
                            artists = artists + ", #{artist.name}"
                        else
                            artists = artist.name

                    cover_art = data.images[..].pop()

                    res.send "#{cover_art.url}?.jpg #{data.name} (album) by #{artists}"


    describe_resource = (res, type, id) ->
        # https://beta.developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow

        url = "https://accounts.spotify.com/api/token"
        auth = "Basic " + new Buffer(env.HUBOT_SPOTIFY_CLIENT_ID + ":" + env.HUBOT_SPOTIFY_CLIENT_SECRET).toString("base64")
        data = "grant_type=client_credentials"

        robot.http(url)
            .header("Authorization", auth)
            .header("Content-Type", "application/x-www-form-urlencoded")
            .post(data) (e, r, b) ->
                if handle_err(res, e, r, b, "POST", url) isnt true
                    try
                        data = JSON.parse b
                    catch
                        res.send "Failed to parse the JSON."
                    token = data.access_token
                    switch type
                        when "track"
                            describe_track(res, id, token)
                        when "album"
                            describe_album(res, id, token)
                        else
                            res.send "I don't know how to describe " + type

    # URI
    robot.hear /(?:spotify:)([a-z]+)(?::)([a-zA-Z0-9]+)/i, (res) ->

        type = res.match[1]
        id = res.match[2]

        describe_resource(res, type, id)

    # URL
    robot.hear /(?:http|https)(?::\/\/open\.spotify\.com\/)([a-z]+)(?:\/)([a-zA-Z0-9]+)(?:.*)/i, (res) ->

        type = res.match[1]
        id = res.match[2]

        describe_resource(res, type, id)

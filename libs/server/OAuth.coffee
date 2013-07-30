###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
restler = require 'restler'
superagent = require 'superagent'
crypto = require 'crypto'

class OAuth

	###
	Encryption Algorithm
	###
	@algorithm: 'aes256' # or any other algorithm supported by OpenSSL

	###
	Encryption Key
	###
	@key: process.env.ENCRYPT_KEY or "c5509e69d605e902999d7621f33424ac5a36a1f8f03c76250d36aefbf4b418c8"

	###
	@param encrypted Encrypted text to be decrypted
	###
	@decrypt: (encrypted) ->
		decipher = crypto.createDecipher OAuth.algorithm, OAuth.key
		decipher.update(encrypted, 'hex', 'utf8') + decipher.final('utf8')

	###
	@param text Text to be encrypted
	###
	@encrypt: (text) ->
		cipher = crypto.createCipher OAuth.algorithm, OAuth.key
		cipher.update(text, 'utf8', 'hex') + cipher.final('hex')

	constructor: (@options) ->
		@clientId = @options.clientId
		@redirectUri = @options.redirectUri
		@loginServer = @options.loginServer
		@clientSecret = @options.clientSecret

	loginUrl: (promptLogin) ->
		url = @loginServer + '/services/oauth2/authorize?' +
			#"scope=chatter_api refresh_token&" +
			'response_type=code' +
			'&format=json' +
			'&client_id=' + @clientId +
			'&redirect_uri=' + @redirectUri +
			'&display=touch'

		if promptLogin
			url += '&prompt=login'

		return url

	###
	@param req Express request object
	@param callback Callback function (err)
	###
	codeHandler: (req, callback) ->
		console.log "Code " + req.query.code

		url = @loginServer + '/services/oauth2/token'

		payload =
			code: req.query.code
			grant_type: 'authorization_code'
			client_id: @clientId
			redirect_uri: @redirectUri
			client_secret: @clientSecret

		###
		superagent
			.post(url)
			.send(payload)
			.end (response) ->
				console.log 'HELLO ' + response.text
				console.log 'HELLO ' + response.body.instance_url
		###

		self = this
		restler.post(url, {data:payload}).on('complete', (data, response) ->
			console.log 'Get SID statusCode ' + response.statusCode
			if response.statusCode == 200
				req.session.sid = data.access_token
				data.refresh_token? req.session.refreshToken = OAuth.encrypt data.refresh_token
				req.session.instanceUrl = data.instance_url
				console.log "Session " + JSON.stringify req.session
				callback {success: true}
			else
				console.log "Obtaining sid failed " + response.statusCode
				callback {error: response}
			).on 'error', (e) ->
				console.error e
				callback {error: e}

	###
	Uses the session instanceUrl and refreshToken to obtain and new access token.
	@param req Express request object
	@param callback Callback function (err)
	###
	refresh: (req, callback) ->
		console.log 'refreshSID instanceUrl: ' + req.session.instanceUrl
		url = req.session.instanceUrl + '/services/oauth2/token'

		if req.session.refreshToken
			refreshToken = OAuth.decrypt req.session.refreshToken
			payload =
				grant_type: 'refresh_token',
				client_id: @clientId,
				client_secret: @clientSecret,
				refresh_token: refreshToken

			restler.post(url, {data:payload}).on('complete', (data, response) ->
				console.log 'got new SID statusCode ' + response.statusCode
				if response.statusCode == 200
					req.session.sid = data.access_token
					callback {success: true}
				else
					callback {error: response}
				).on 'error', (e) ->
					console.error e
					callback {error: e}
		else
			console.log 'No refresh token found.'
			callback {error:
				statusCode: 401
				text: 'No refresh token found. Skipping refresh.'
			}

	###
	Revokes the users session Id
	###
	logout: (req, callback) ->
		url = @loginServer + '/services/oauth2/revoke'
		console.log 'logout ' + url
		superagent('GET', url)
			.send({token: req.session.sid})
			.end (response) ->
				console.log 'Revoked sid: ' + response.text
				console.log 'Revoked status: ' + response.statusCode
				if response.statusCode is 200
					req.session.sid = null
					req.session.refreshToken = null
					req.session.instanceUrl = null
					callback {success: true}
				else
					callback {statusCode: response.statusCode}

module.exports = OAuth
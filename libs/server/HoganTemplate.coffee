###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
Hogan = require 'hogan'
fs = require 'fs'

class HoganTemplate

	###
	@param req Express request object
	@param res Express response object
	@param path Absolute path to the templates e.g. __dirname + '/../templates/'
	@param templates Array of template names e.g. ['foo', 'bar']
	@param namespace Optional JavaScript namespace. (Defaut 'T')
	###
	@load: (req, res, path, templates, namespace = 'T') ->
		compileTemplate = (template, callback) ->
			filename = path + template + '.hogan'
			fs.readFile filename, (err, contents) ->
				if err
					throw err
				else
					temp = Hogan.compile contents.toString(), {asString : true}
					callback '\n' + namespace + '.' + template + '=' + temp

		result = namespace + '={};'
		current = 0
		for template in templates
			compileTemplate template, (templateJS) ->
				result += templateJS
				# when all templates have been read
				# send the generated JS file back.
				if ++current >= templates.length
					res.header 'Content-Type', 'text/javascript'
					res.send result				

module.exports = HoganTemplate
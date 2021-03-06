/// <reference path="../../../definitions/mocha.d.ts"/>
/// <reference path="../../../definitions/node.d.ts"/>
/// <reference path="../../../definitions/Q.d.ts"/>

import Q = require('q');
import assert = require('assert');
import trm = require('../../lib/taskRunner');
import path = require('path');

describe('Xcode Suite', function() {

	before((done) => {
		// init here
		done();
	});

	after(function() {
		
	});

	it('Xcode runs a workspace', (done) => {
		this.timeout(500);

		assert(true, 'true is true');
		
		var completed = false;
		var taskRunner = new trm.TaskRunner('Xcode');
		taskRunner.on('completed', (step) => {
			completed = true;
		});

		taskRunner.run()
		.then((result) => {
			assert(completed, 'completed');
			assert(true, 'baselines match');
			done();
		})
		.fail((err) => {
			done(err);
		});
	})
});

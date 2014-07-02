'use strict';

exports = module.exports = function error1(context, done) {
  done(new Error('error1'), null);
};
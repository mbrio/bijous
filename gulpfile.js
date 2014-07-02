'use strict';

var gulp = require('gulp');
var jshint = require('gulp-jshint');
var mocha = require('gulp-mocha');
var istanbul = require('gulp-istanbul');

gulp.task('lint', function gulpLint(cb) {
  gulp.src(['./*.js', './test/**/*.js'])
    .pipe(jshint())
    .pipe(jshint.reporter('default'))
    .on('end', cb);
});

gulp.task('test', ['lint'], function gulpCoverage(cb) {
  gulp.src(['./index.js'])
    .pipe(istanbul())
    .on('finish', function () {
      gulp.src(['./test/**/*-test.js'])
        .pipe(mocha())
        .pipe(istanbul.writeReports())
        .on('end', cb);
    });
});

gulp.task('default', ['test']);
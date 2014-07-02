'use strict';

var gulp = require('gulp');
var jshint = require('gulp-jshint');
var mocha = require('gulp-mocha');
var istanbul = require('gulp-istanbul');
var jsdoc = require('gulp-jsdoc');

var srcFiles = ['./index.js'];

gulp.task('lint', function gulpLint() {
  return gulp.src(['./*.js', './test/**/*.js'])
    .pipe(jshint())
    .pipe(jshint.reporter('default'));
});

gulp.task('test', ['lint'], function gulpCoverage(cb) {
  gulp.src(srcFiles)
    .pipe(istanbul())
    .on('finish', function () {
      gulp.src(['./test/**/*-test.js'])
        .pipe(mocha())
        .pipe(istanbul.writeReports())
        .on('end', cb);
    });
});

gulp.task('docs', function gulpDoc(cb) {
  return gulp.src(['./README.md'].concat(srcFiles))
    .pipe(jsdoc('./docs'));
});

gulp.task('doc', ['docs']);

gulp.task('default', ['test']);
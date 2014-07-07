gulp = require 'gulp'
coffeelint = require 'gulp-coffeelint'
mocha = require 'gulp-mocha'
istanbul = require 'gulp-istanbul'
biscotto = require 'gulp-biscotto'

srcFiles = ['./src/**/*.coffee']
libFiles = ['./lib/**/*.js']

gulp.task 'lint', ->
  gulp.src srcFiles.concat ['./*.coffee', './test/**/*.coffee']
    .pipe coffeelint()
    .pipe coffeelint.reporter()

gulp.task 'test', ['lint'], (cb) ->
  gulp.src libFiles
    .pipe istanbul()
    .on 'finish', ->
      gulp.src ['./test/**/*-test.js']
        .pipe mocha()
        .pipe istanbul.writeReports()
        .on 'end', cb

  return

gulp.task 'docs', ->
  biscotto()
    .pipe gulp.dest './docs'

gulp.task 'doc', ['docs']

gulp.task 'default', ['test']

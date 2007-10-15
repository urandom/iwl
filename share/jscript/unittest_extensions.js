Object.extend(Test.Unit.Runner.prototype, (function() {
  function delayCallback(test) {
    if(test.delay) return;
    clearInterval(test.delayInterval);
    this.runTests.call(this);
  }

  return {
    runTests: function() {
      var test = this.tests[this.currentTest];
      if (!test) {
        // finished!
        this.postResults();
        this.logger.summary(this.summary());
        return;
      }
      if(!test.isWaiting && !test.isDelaying) {
        this.logger.start(test.name);
      }
      test.run();
      if(test.isWaiting) {
        this.logger.message("Waiting for " + test.timeToWait + "ms");
        setTimeout(this.runTests.bind(this), test.timeToWait || 1000);
      } else if(test.isDelaying) {
        this.logger.message("Waiting ...");
        test.delayInterval = setInterval(delayCallback.bind(this, test), 100);
      } else {
        this.logger.finish(test.status(), test.summary());
        this.currentTest++;
        // tail recursive, hopefully the browser will skip the stackframe
        this.runTests();
      }
    }
  }
})());

Object.extend(Test.Unit.Testcase.prototype, {
  delay: function(nextPart) {
    this.isDelaying = this.delay = true;
    this.test = nextPart;
  },
  proceed: function() {
    this.delay = false;
  },
  run: function() {
    try {
      try {
        if (!this.isWaiting && !this.isDelaying) this.setup.bind(this)();
        this.isWaiting = this.isDelaying = false;
        this.test.bind(this)();
      } finally {
        if(!this.isWaiting && !this.isDelaying) {
          this.teardown.bind(this)();
        }
      }
    }
    catch(e) { this.error(e); }
  }
});

#!/bin/bash
HOST=yatodo.nstal.me
rsync -avPziou ./* $HOST:~/yatodo/ --exclude="yatodo.log" --exclude="yatodo.pid"
rsync -avPziouL ~/yatodo/static/js/lib/leaf.js puff:~/yatodo/static/js/lib/leaf.js

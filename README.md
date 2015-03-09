# gitmon

Monitor your git repository on the server, instead of a CI server (like travis-ci). This works better for places when you have firewalls and your CI server cannot reach your machine that has the git repo. Not intended for production use...

You'll need a file that has things gitmon should do whenever the repo is updated.

`vi path/to/git/repo/.gitmon/changed`

```
#!/bin/bash

composer install
mail bob@gmail.com "it updated"
```

Next setup a crontab job

```
#   crontab -e
#   */2 * * * * gitmon path/to/git/repo
```

That is it. Anytime your repo is updated, the changed script will be run.

#!/bin/sh
# $Id$

ROOT=.

chown -R proj:proj ${ROOT}
chown -R apache:apache ${ROOT}/www/sessions
find ${ROOT} -type d -exec chmod 775 {} \;
find ${ROOT} -type f -exec chmod 664 {} \;

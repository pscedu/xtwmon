#!/bin/sh
# $Id$

ROOT=.

sudo chown -R proj:proj ${ROOT}
find ${ROOT} -type d -exec chmod 775 {} \;
find ${ROOT} -type f -exec chmod 664 {} \;

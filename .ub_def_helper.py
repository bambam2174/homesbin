#!/usr/bin/env python

import json,sys;

obj=json.load(sys.stdin);

#print "len(obj) = ", len(obj);
#print "len(obj[\"list\"]) = ", len(obj["list"]);
#print obj["list"][0]["definition"];

for i in obj["list"]:
   # print "i = ", i
    print i["definition"];
    print "\n###############################################\n"

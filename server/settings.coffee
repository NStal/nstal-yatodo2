path = require("path")
_ = {}
_.root = "/home/wuminghan/yatodo/"
_.database = {
    "name":"yatodo"
    "host":"localhost"
    "port":27017
    "option":{}
}
_.salt = "!@$#%!@#HatsuneDaisuki{raw}ToPreventACrack!@#%!@$#@^)+{:@#F!@$"
_.defaultExpire = 31*24*60*60*1000
_.sessionSecret = "HatsuneDaisuki"
exports.settings = _
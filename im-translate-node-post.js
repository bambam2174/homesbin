#!/usr/bin/env node

var processor = process.argv.shift();

var path2script = process.argv.shift();

var text2translate = process.argv.shift();
var lsource = process.argv.shift();
var ltarget = process.argv.shift();
//console.log('args 1', text2translate);

fetch("https://translate.google.sn/translate_a/single", {
  "headers": {
    "accept": "*/*",
    "accept-language": "en-US,en-GB;q=0.9,en;q=0.8,de-DE;q=0.7,de;q=0.6,tr-TR;q=0.5,tr;q=0.4",
    "cache-control": "no-cache",
    "content-type": "application/x-www-form-urlencoded",
    "pragma": "no-cache",
    "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"macOS\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "none",
    "x-client-data": "CIa2yQEIpLbJAQiKksoBCKmdygEIgP/KAQiWocsBCJv+zAEIhqDNAQje680BCIPwzQEIp/PNARjymM0BGKfqzQE=",
    "cookie": "__Secure-ENID=14.SE=MVoQ8GrbJMkYz8GBcNp3tjiD-VFO5azx0Mnhd46XroVKFGll7R8Joa3LAOmrIQxPvOnjlw4wwwVMR_MlXHc-SQZ0MWKv2qzkdtnWMKfrQd6XfVQKX-7F9_Ed_7NN2UDPB7fM4mNmpYo39Joffix5uTE5oM-QvxhKj8WY-MvH7u0; NID=511=IPVIDjZ9he1CwNxFo62_oA4SDSHARB8aLVIfAX78DUvoetHZxzg2qTqpab4WTFs6bhbN-N3Pj9p-gMNvSCbETDFplGmi2tKiAvnYakwfzBL5Fu54BrqzudVR5yQu8g5Qdfq876BqmmrzYeT0yOZ_1U7hy4espEseDfq6bburZOY"
  },
  "referrerPolicy": "strict-origin-when-cross-origin",
  "body": "client=gtx&dt=t&dt=bd&dj=1&source=input&q="+ encodeURIComponent(text2translate) + "&sl="+lsource+"&tl="+ltarget+"&hl=en",
  "method": "POST"
}).then(response => {
    return response.json();
}).then(translation => {
    translation.sentences.forEach(sentence => {
        console.log(sentence.trans);
    })
});

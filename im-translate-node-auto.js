#!/usr/bin/env node

var processor = process.argv.shift();

var path2script = process.argv.shift();

var text2translate = process.argv.shift();
var lsource = process.argv.shift();
var ltarget = process.argv.shift();

fetch("https://translate.google.es/translate_a/single?client=gtx&dt=t&dt=bd&dj=1&source=input&q="+ encodeURIComponent(text2translate) + "&sl=auto&tl=en&hl=en", {
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
    "cookie": "__Secure-ENID=14.SE=oC4QZ23c-kSG_9KtXhjUVN_50Yv_1o7M7_7efMeTt9kBv5Z6VoAWnYwZSJx-4HpgVq4MQ0nl8lfY3QPjnJrRdj6puZtS6Ru4wuJkrK3rMQZ-uBVLitCIpTIE6ZP7ZFfoc3LHlgnYpxFp7y851Ft2mTjr8H7MFW04oGTpzTy6lCE; NID=511=PY5yutPegOACBCUNU35XLifFql5CLraO7by6Yk5GgwSv9LoIs_knv6hiwGZhJBzayppgHbtnuHs5Z4ECWn0zoOqLNDXT8V9KmSNMA6ohLUfhhfaKCIVfbhnIvBN1Kx8w1Y4SnlIXL7_6X0jBu6hsQCiwYlaoycso6NcuBQxARMQ"
  },
  "referrerPolicy": "strict-origin-when-cross-origin",
  "body": null,
  "method": "GET"
}).then(response => {
    return response.json();
}).then(translation => {
    console.log(translation.sentences[0].trans);
});



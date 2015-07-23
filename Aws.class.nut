class Aws {

    static version = [0,1,0];
    static aws_api_version = "2010-03-31";

    // URLs
    static AWS_URL = "amazonaws.com";

    // OAuth
    _secret_key = null; 
    _access_key = null;
    _region = null;

    constructor (access_key, secret_key, region) {
        _secret_key = secret_key;
        _access_key = access_key;
        _region = region;
    }

    function awsDateTime(time){
        local ts = date(time,"u");
        local datestamp = "" + ts.year + ""
        + format("%02d",ts.month+1) + ""
        + format("%02d", ts.day) ;
        local timestamp = datestamp + "T"
        + format("%02d", ts.hour) + ""
        + format("%02d", ts.min)  + ""
        + format("%02d", ts.sec) + "Z";
        local awsTS = {};
        awsTS.rawset("datestamp", datestamp);
        awsTS.rawset("timestamp", timestamp);
        return awsTS;
    }

    function binToHex(s){
        local hexStr = "";
        foreach(c in s){
        // "02" ensures single-digit value are presented with two digits
        hexStr = hexStr + format("%02x", c) ;
        }
        return hexStr;
    }

    function hexDigest(str){
        local binHash= http.hash.sha256(str);
        return binToHex(binHash);
    }

    function sign256(key, msg){
        local sHash = http.hash.hmacsha256(msg, key);    
        return sHash;
    }

    function getSignatureKey(key, date_stamp, regionName, serviceName){
        local kDate = sign256(("AWS4" + key), date_stamp);
        local kRegion = sign256(kDate, regionName);
        local kService = sign256(kRegion, serviceName);
        local kSigning = sign256(kService, "aws4_request");
        return kSigning
    }

    function snsPublish(target_arn, subject, message){

        local secret_key = _secret_key; 
        local access_key = _access_key;
        local region = _region;

        local currTime = time();
        local datestamp = awsDateTime(currTime).datestamp;
        local amz_date = awsDateTime(currTime).timestamp;
        local service = "sns";
        local method = "POST";
        local host = service + "." + region + "." + AWS_URL;
        local endpoint = "http://" + host + "/";
        local content_type = "application/x-www-form-urlencoded; charset=utf-8";

        local paramMap = {};
        paramMap.rawset("Action","Publish");
        paramMap.rawset("Version", aws_api_version);
        paramMap.rawset("TargetArn", target_arn);
        paramMap.rawset("Message", message);
        if( subject != null)
            paramMap.rawset("Subject", subject);
        local request_parameters =  http.urlencode(paramMap);

        // ************* TASK 1: CREATE A CANONICAL REQUEST *************
        local canonical_uri = "/" ;
        local canonical_querystring = "";
        local canonical_headers = "content-type:" + content_type + "\n" + "host:" + host + "\n" + "x-amz-date:" + amz_date + "\n";
        local signed_headers = "content-type;host;x-amz-date";
        local payload_hash = hexDigest(request_parameters);
        local canonical_request = method + "\n" + canonical_uri + "\n" + canonical_querystring + "\n" + canonical_headers + "\n" + signed_headers + "\n" + payload_hash;

        // ************* TASK 2: CREATE THE STRING TO SIGN*************
        local algorithm = "AWS4-HMAC-SHA256"
        local credential_scope = datestamp + "/" + region + "/" + service + "/" + "aws4_request"
        local string_to_sign = algorithm + "\n" +  amz_date + "\n" +  credential_scope + "\n" +  hexDigest(canonical_request);


        // ************* TASK 3: CALCULATE THE SIGNATURE *************
        local signing_key = getSignatureKey(secret_key, datestamp, region, service)

        local signature = binToHex(sign256(signing_key, string_to_sign)); 

        // ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************
        local authorization_header = algorithm + " " + "Credential=" + access_key + "/" + credential_scope + ", " +  "SignedHeaders=" + signed_headers + ", " + "Signature=" + signature

        local headers = {"Content-Type":content_type, "X-Amz-Date":amz_date, "Authorization":authorization_header}

        // ************* SEND THE REQUEST *************
        local response = http.post(endpoint, headers, request_parameters).sendsync();

    //    server.log(http.jsonencode(response))
        server.log("Code: " + response.statuscode + ". Message: \n" + response.body);

    }
}

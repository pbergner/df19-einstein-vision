/* helper methods for Einstein API */
public with sharing class Helper_Einstein {
	public static String access_token;
	public enum EinsteinAPITypes {IMAGE,IMAGE_MULTI_LABEL,SENTIMENT,INTENT}
	
	/*  update contentVersion file with einstein vision results*/
	public static ContentVersion updateWithEinsteinVisionResult(ContentVersion thisCV, String visionModel) {
		return visionCallout(thisCV,visionModel);
	}

	/* used to do callout for image feedback  */
	public static String predictionFeedbackCallout(String name, String expectedLabel, String modelId, String contentVersionId) {
		access_token = generateToken();

		ContentVersion thisFile = [SELECT Id,VersionData FROM ContentVersion WHERE Id=:contentVersionId];
		Einstein_PredictionService service = new Einstein_PredictionService(access_token, EinsteinAPITypes.IMAGE_MULTI_LABEL);
		return service.createFeedbackImageExample(name,expectedLabel,modelId,thisFile.versionData);
	}

	/* do actual callout to vision API and return updated ContentVersion file */
	private static ContentVersion visionCallout(ContentVersion thisFile,String visionModel) {
		access_token = generateToken();
		Einstein_PredictionService service = new Einstein_PredictionService(access_token, EinsteinAPITypes.IMAGE_MULTI_LABEL);
		Einstein_PredictionResult predictionResult = service.predictImageBlob(visionModel,thisFile.versionData,thisFile.title,5000,'');
		Einstein_Probability winningProb;
		
		for (Einstein_Probability currentProb : predictionResult.probabilities) {
			if (winningProb == null) {
				winningProb = currentProb;
			}
			else if (currentProb.probability > winningProb.probability) {
				winningProb = currentProb;
			}
		}
		thisFile.image_type__c = winningProb.label;
		thisFile.probability__c =String.valueOf(Math.round(winningProb.probability*100))+'%';
		
		return thisFile;
	}


	/* generate a token through a callout to Einstein using the Setup info in the custom metadata type */
	public static String generateToken() {
		// TEST CODE ONLY
		if (Test.isRunningTest()) {
			return 'test_val';
		}
		// dont run twice
		if (access_token!=null && access_token!='') {
			return access_token;
		}
		List<Einstein_Details__mdt> einsteinSetupInfo = [SELECT Email__c,RSA_Private_Key__c FROM Einstein_Details__mdt LIMIT 1];
		if (einsteinSetupInfo.size() > 0 && einsteinSetupInfo[0].rsa_private_key__c !=null) {
			String keyContents = generateKey(einsteinSetupInfo[0].rsa_private_key__c);
			if (keyContents == null) {
				return null;
			}
			// Get a new token
			Einstein_JWT jwt = new Einstein_JWT('RS256');
			//jwt.cert = 'JWTCert'; // Uncomment this if you used a Salesforce certificate to sign up for an Einstein Platform account
			jwt.pkcs8 = keyContents; // Comment this if you are using jwt.cert
			jwt.iss = 'developer.force.com';
			jwt.sub = einsteinSetupInfo[0].email__c;
			jwt.aud = 'https://api.einstein.ai/v2/oauth2/token';
			jwt.exp = '3600';
			return getAccessToken('https://api.einstein.ai/v2/oauth2/token', jwt);	
		}
		return null;
	}

	/* format key */
	public static String generateKey(String rsaKey) {
		String keyContents = rsaKey;
		keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
		keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
		keyContents = keyContents.replace('\n', '');
		return keyContents;
	}

	/* callout to get access token from Einstein */
	public static String getAccessToken(String tokenEndpoint, Einstein_JWT jwt) {
		String access_token = ''; 
		String body = 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt.issue();
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint(tokenEndpoint);
		req.setHeader('Content-type', 'application/x-www-form-urlencoded');
		req.setBody(body);
		Http http = new Http();
		HTTPResponse res = http.send(req);
		System.debug('res : ' + res);
		if ( res.getStatusCode() == 200 ) {
			System.JSONParser parser = System.JSON.createParser(res.getBody());
			while (parser.nextToken() != null) {
				if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
					parser.nextToken();
					access_token = parser.getText();
					break;
				}
			}
		}
		return access_token;
	}

	/* prediction result wrapper class */
	public class Einstein_PredictionResult  {
		public List<Einstein_Probability> probabilities {get; set;}
	}

	/* probabilities for models returned from Einstein*/
	public class Einstein_Probability {
		public String label {get; set;}
		public Double probability {get; set;}
	}

	/* JWT Token class */
	public class Einstein_JWT {
		public String alg {get;set;}
		public String iss {get;set;}
		public String sub {get;set;}
		public String aud {get;set;}
		public String exp {get;set;}
		public String iat {get;set;}
		public Map<String,String> claims {get;set;}
		public Integer validFor {get;set;}
		public String cert {get;set;}
		public String pkcs8 {get;set;}
		public String privateKey {get;set;}
		
		public final String HS256 = 'HS256';
		public final String RS256 = 'RS256';
		public final String NONE = 'none';

		// constructor
		public Einstein_JWT(String alg) {
			this.alg = alg;
			this.validFor = 300;
		}

		public String issue() {
			String jwt = '';
			JSONGenerator header = JSON.createGenerator(false);
			header.writeStartObject();
			header.writeStringField('alg', this.alg);
			header.writeEndObject();
			String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
			JSONGenerator body = JSON.createGenerator(false);
			body.writeStartObject();
			body.writeStringField('iss', this.iss);
			body.writeStringField('sub', this.sub);
			body.writeStringField('aud', this.aud);
			Long rightNow = (dateTime.now().getTime()/1000)+1;
			body.writeNumberField('iat', rightNow);
			body.writeNumberField('exp', (rightNow + validFor));

			if (claims != null) {
				for (String claim : claims.keySet()) {
					body.writeStringField(claim, claims.get(claim));
				}
			}
			body.writeEndObject();
			jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
			if ( this.alg == HS256 ) {
				Blob key = EncodingUtil.base64Decode(privateKey);
				Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
				jwt += '.' + base64URLencode(signature);
			} 
			else if ( this.alg == RS256 ) {
				Blob signature = null;
				if (cert != null ) {
					signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
				} 
				else {
					Blob privateKey = EncodingUtil.base64Decode(pkcs8);
					signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKey);
				}
				jwt += '.' + base64URLencode(signature);
			} 
			else if ( this.alg == NONE ) {
				jwt += '.';
			}
			return jwt;
		}

		public String base64URLencode(Blob input){ 
			String output = encodingUtil.base64Encode(input);
			output = output.replace('+', '-');
			output = output.replace('/', '_');
			while ( output.endsWith('=')){
				output = output.subString(0,output.length()-1);
			}
			return output;
		}
	}
}
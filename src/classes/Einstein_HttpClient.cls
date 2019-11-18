/* Handles HTTP connection with Einstein API */
public class Einstein_HttpClient {

	private String url;
	private Boolean isDelete = false;
	private Boolean isPost = false;
	private Boolean isPut = false;
	private Einstein_PredictionService predictionService;
	private JSONParser parser;
	private Blob body;

	// Values for HTTP response
	private String errorMessage;
	private Integer statusCode;
	private String statusMessage;

	// constructor
	public Einstein_HttpClient(Einstein_PredictionService predictionService, String url) {
		this.predictionService = predictionService;
		if (!url.endsWith('apiusage')) {
			this.url = predictionService.baseUrl + url;
		} else {
			this.url = url;
		}
	}
	// constructor 
	public Einstein_HttpClient(Einstein_PredictionService predictionService, String url, Blob body) {
		this.predictionService = predictionService;
		this.url = predictionService.baseUrl + url;
		this.body = body;
		isPost(true);
	}
	// get isdelete
	public boolean isDelete() {
		return isDelete;
	}
	// set isdelete
	public void isDelete(boolean isDelete) {
		this.isDelete = isDelete;
	}
	// get ispost
	public boolean isPost() {
		return isPost;
	}
	// set ispost
	public void isPost(boolean isPost) {
		this.isPost = isPost;
	}
	// get isput
	public boolean isPut() {
		return isPut;
	}
	// set isput
	public void isPut(boolean isPut) {
		this.isPut = isPut;
	}
	// execute http call
	public void execute() {
		if (url!=null) {
			
			HttpRequest request = new HttpRequest();
			Helper_Einstein.access_token = Helper_Einstein.generateToken();
			request.setHeader('Authorization', 'Bearer ' + Helper_Einstein.access_token);
			request.setHeader('Cache-Control', 'no-cache');
			
			request.setMethod('GET');

			if (isDelete()) {
				request.setMethod('DELETE');
			} else if (isPost() || isPut()) {
				request.setHeader('Content-Type', Einstein_HttpBodyPart.GetContentType());
				request.setBodyAsblob(body);
				if (isPut()) {
					request.setMethod('PUT');
				} else {
					request.setMethod('POST');
				}
			}

			request.setEndpoint(url);

			Http http = new Http();
			HTTPResponse response = http.send(request);

			predictionService.isExecuting(true);
			
			updateResponseValues(response);
		}
	}
	// return true if error response
	public Boolean isError() {
		return (getStatusCode()!=200 && getStatusCode()!=204);
	}
	// get statuscode
	public Integer getStatusCode() {
		return statusCode;
	}
	// get statusmessage
	public String getStatusMessage() {
		return statusMessage;
	}
	// get responseerror
	public String getResponseError() {
		return errorMessage;
	}
	// parse data from response
	private void updateResponseValues(HTTPResponse response) {
		statusCode = response.getStatusCode();
		statusMessage = response.getStatus();
		System.debug(response.getBody());
		try {
			parser = JSON.createParser(response.getBody());
		} catch (Exception e) {
			errorMessage = 'Could not read JSON data';
			return;
		}
		if (getStatusCode()==200) {
			Boolean hasDataToken = false;
			while (parser.nextToken()!=null) {
				if (parser.getCurrentToken()==JSONToken.FIELD_NAME) {
					String currentProperty = parser.getText();
					if (currentProperty=='data' || currentProperty=='metricsData') {
						parser.nextToken();
						hasDataToken = true;
						break;
					}
				}
			}
			if (!hasDataToken) {
				parser = JSON.createParser(response.getBody());
			}
		} else {
			while (parser.nextToken()!=null) {
				if (parser.getCurrentToken()==JSONToken.FIELD_NAME) {
					String currentProperty = parser.getText();
					if (currentProperty=='message') {
						parser.nextToken();
						errorMessage = parser.getText();
						break;
					}
				}
			}
		}
		predictionService.isExecuting(false);
	}
	// get url
	public String getUrl() {
		return url;
	}
	// get parser
	public JSONParser getParser() {
		return parser;
	}

}
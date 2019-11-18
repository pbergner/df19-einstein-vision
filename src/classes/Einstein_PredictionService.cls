public class Einstein_PredictionService {
		private String BASE_URL = 'https://api.einstein.ai/v2';
	
		private String API_USAGE = BASE_URL + '/apiusage';
		private String OAUTH2 = BASE_URL + '/oauth2/token';
		
		private boolean isExecuting = false;
		private String bearerToken = '';
		public Integer httpStatusCode = 0;
		private Helper_Einstein.EinsteinAPITypes typeEnum;
		private String typeString;
		public String baseUrl;

		public Einstein_PredictionService(String bearerToken, Helper_Einstein.EinsteinAPITypes typeEnum) {
			this.bearerToken = bearerToken;
			this.typeEnum = typeEnum;
			this.baseUrl = resolveBaseUrl();
			this.typeString = resolveType();
		}

		private String resolveType() {
			if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.IMAGE) {
				return 'image';
			} else if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.IMAGE_MULTI_LABEL) {
				return 'image-multi-label';
			} else if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.SENTIMENT) {
				return 'sentiment';
			} else if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.INTENT) {
				return 'intent';
			}
			return '';
		}

		public String resolveBaseUrl() {
			if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.IMAGE) {
				return BASE_URL + '/vision';
			} else if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.IMAGE_MULTI_LABEL) {
				return BASE_URL + '/vision';
			} else if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.SENTIMENT) {
				return BASE_URL + '/language';
			} else if (this.typeEnum == Helper_Einstein.EinsteinAPITypes.INTENT) {
				return BASE_URL + '/language';
			}
			return '';
		}

		/* IMAGE FEEDBACK EXAMPLE  */
		public String createFeedbackImageExample(String name, String expectedLabel, String modelId, Blob fileBlob) {
	        System.debug('Starting createFeedbackImageExample call from blob');
	        Einstein_HttpBodyPartFeedbackExample parts = new Einstein_HttpBodyPartFeedbackExample(name, expectedLabel, modelId, EncodingUtil.base64Encode(fileBlob), Einstein_HttpBodyPartFeedbackExample.Types.BASE64);
	        Einstein_HttpClient client = new Einstein_HttpClient(this, '/feedback', parts.build());
	        System.debug('Target URL is ' + client.getUrl());
	        client.isPost(true);
	        client.execute();
	       	
	       	System.debug('Call createFeedbackImageExample from blob has been executed.');
	        if (!client.isError()) {
	            return 'feedback accepted';
	        }
	        else {
	        	return 'feedback failed';
	        }
	    }

		/**
		* Predicts the association of the given image as Blob to a trained model.
		* @param modelId
		* The Einstein_Model that should be used for the prediction.
		* @param base64
		* The image that should be predicted.
		* @param numResults
		* The number of results that should be max. returned.
		* @param sampleId
		* Optional. A string that gets returned as an association with the predicted image.
		* @return
		* An object of type Helper_Einstein.Einstein_PredictionResult.
		*/
		public Helper_Einstein.Einstein_PredictionResult predictImageBlob(String modelId,Blob fileBlob,String fileName,Integer numResults,String sampleId) {
			System.debug('Starting predict call with model ' + modelId + ' for blob');
			String base64FileData = EncodingUtil.base64Encode(fileBlob);
			System.debug('base64FileData : ' + base64FileData);
			fileBlob = null;
			Einstein_HttpBodyPartPrediction parts = new Einstein_HttpBodyPartPrediction(modelId,base64FileData , numResults, sampleId, Einstein_HttpBodyPartPrediction.Types.BASE64);
			parts.setFileName(fileName);
			base64FileData = null;
			Einstein_HttpClient client = new Einstein_HttpClient(this, '/predict', parts.build());
			parts = null;
			System.debug('Target URL is ' + client.getUrl());
			client.execute();
			System.debug('Call predict has been executed.');
			if (!client.isError()) {
				Helper_Einstein.Einstein_PredictionResult predictions = (Helper_Einstein.Einstein_PredictionResult)client.getParser().readValueAs(Helper_Einstein.Einstein_PredictionResult.class);
				System.debug('Image has been predicted.');
				client = null;
				return predictions;
			}
			handleError(client.getStatusCode(), client.getResponseError());
			return null;
		}

		/**
		* 
		* @return
		*/
		public boolean isExecuting() {
			return isExecuting;
		}
		
		/**
		* 
		* @param isExecuting
		*/
		public void isExecuting(boolean isExecuting) {
			this.isExecuting = isExecuting;
		}

		/**
		* 
		* @param message
		*/
		private void handleError(Integer statusCode, String message) {
			httpStatusCode = statusCode;
			System.debug(LoggingLevel.Error, 'Response finished with Error: ' + message);
		}
	}
/* builds http body for einstein http */
public class Einstein_HttpBodyPartPrediction extends Einstein_HttpBodyPart {
	
	public enum Types {
		BASE64,
		FILEBLOB,
		URL,
		DOCUMENT
	}
	
	private String modelId;
	private String data;
	private String sampleId;
	private Types type;
	private String fileName;
	private Integer numResults;

	// constructor 
	public Einstein_HttpBodyPartPrediction(String modelId, String data, Integer numResults, String sampleId, Einstein_HttpBodyPartPrediction.Types type) {
		this.modelId = modelId;
		this.data = data;
		this.numResults = numResults;
		this.sampleId = sampleId;
		this.type = type;
	}
	
	// build http body
	public Blob build() {
		String body = '';
		body += WriteBoundary();
		body += WriteBodyParameter('modelId', modelId);
		if (sampleId!=null && !sampleId.equals('')) {
			body += WriteBoundary();
			body += WriteBodyParameter('sampleId', sampleId);
		}
		body += WriteBoundary();
		if (type==Types.BASE64) {
			body += WriteBlobBodyParameter('sampleContent',data,fileName);
		} else if (type==Types.URL) {
			body += WriteBodyParameter('sampleLocation', data);
		} else if (type==Types.DOCUMENT) {
			body += WriteBodyParameter('document', data);
		}
		if (numResults>0) {
			body += WriteBoundary();
			body += WriteBodyParameter('numResults', numResults);
		}
		body += WriteBoundary(EndingType.CrLf);
		Blob bodyBlob = EncodingUtil.base64Decode(body);
		return bodyBlob;
	}
	
	// get modelid
	public String getModelId() {
		return modelId;
	}

	// set modelid
	public void setModelId(String modelId) {
		this.modelId = modelId;
	}

	// get fileName
	public String getFileName() {
		return fileName;
	}

	// set fileName
	public void setFileName(String fileName) {
		this.fileName = fileName;
	}

	// get data
	public String getData() {
		return data;
	}

	// set data
	public void setData(String data) {
		this.data = data;
	}

	// get sampleid
	public String getSampleId() {
		return sampleId;
	}

	// set sampleid
	public void setSampleId(String sampleId) {
		this.sampleId = sampleId;
	}

	// get type
	public Types getType() {
		return type;
	}

	// set type
	public void setType(Types type) {
		this.type = type;
	}

}
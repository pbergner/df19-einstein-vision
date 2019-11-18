/* Controller for EinsteinVision page */
public with sharing class Ctl_EinsteinVision {

	public class VisionResult {
		public String probability;
		public String label;
		public String sfId;

		public visionResult() {}
	}

	/* constructor */
	public Ctl_EinsteinVision() {
		
	}

	/* called to upload image for image classification via Einstein Vision */
	@remoteAction
	public static VisionResult uploadImage(String imageName, String imageBase64) {
		ContentVersion newImage = new ContentVersion();
		newImage.title = imageName;
		newImage.pathOnClient = newImage.title;
		newImage.versionData = EncodingUtil.base64Decode(imageBase64);
		List<Einstein_Details__mdt> einsteinSetupInfo = [SELECT Model_Number__c FROM Einstein_Details__mdt LIMIT 1];
		String visionModel = einsteinSetupInfo[0].model_number__c;
		newImage = Helper_Einstein.updateWithEinsteinVisionResult(newImage,visionModel);
		System.debug('newImage.probability__c : ' + newImage.probability__c);

		insert newImage;

		VisionResult einsteinResult = new VisionResult();
		einsteinResult.probability = newImage.probability__c;
		einsteinResult.label = newImage.image_type__c;
		einsteinResult.sfId = newImage.id;

		return einsteinResult;
	}

	/* USE THIS TO BUILD IMAGE FEEDBACK BUTTONS */
	@remoteAction
	public static String imageFeedback(String expectedLabel,String contentVersionId) {
		List<Einstein_Details__mdt> einsteinSetupInfo = [SELECT Model_Number__c FROM Einstein_Details__mdt LIMIT 1];
		String visionModel = einsteinSetupInfo[0].model_number__c;
		return Helper_Einstein.predictionFeedbackCallout('feedbackExample',expectedLabel,visionModel,contentVersionId);
	}
}
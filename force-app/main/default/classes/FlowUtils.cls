public with sharing class FlowUtils {
    public class FlowOutput {
		@InvocableVariable(label='Record type id')
		public Id recordTypeId;
	}

	public class FlowInput {
		@InvocableVariable
		public String objectName;
		@InvocableVariable
		public String recordTypeName;
	}

	@invocableMethod(label='Get recordTypeId from name')
	public static FlowOutput[] getRecordTypeId(List<FlowInput> infos) {
		FlowInput info = infos[0];
		FlowOutput output = new FlowOutput();

		output.recordTypeId = SchemaUtils.getRecordTypeId(info.objectName, info.recordTypeName);
		
		return new List<FlowOutput>{output};
	}
}
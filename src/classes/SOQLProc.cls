public with sharing class SOQLProc extends AbstractProcessor {

    public override Response process(Request request) {
        this.request = request;

        this.retrieveRecords();

        return this.response;
    }

    private void retrieveRecords() {
        String soqlStr = this.request.getString('SOQL');
        List<SObject> records = Database.query(soqlStr);
        this.response.getMapper().mapFromListSObjects('records', records);
    }
}
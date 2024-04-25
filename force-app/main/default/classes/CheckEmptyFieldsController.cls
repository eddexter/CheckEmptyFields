public without sharing class CheckEmptyFieldsController {

    @InvocableMethod(label='Check empty fields' description='Returns information about empty fields in record')
    public static List<ResultToFlow> checkEmptyFromFlow(List<Request> requests) {
        Request req; 
        req = requests.get(0);

        Result res;
        res = checkEmptyFields(req.recordId, req.fieldsetName, req.keyField, req.addCheckbox, true);

        ResultToFlow resToFlow;
        resToFlow = new ResultToFlow(res);

        List<ResultToFlow> ret;
        ret = new List<ResultToFlow>();
        ret.add(resToFlow);
        return ret;
    }
        
    
    //Parâmetros: 
    //recordId -> Id do registro a ser checado
    //fieldSetName -> Nome do fielset que determinado os campos obrigatórios.
    //Nunca inserir id no fieldset e sempre inserir o campo enviado como keyfield.
    //keyfield -> Campo que será retornado como nome do Registro. É dinâmico pois na maioria dos casos será Name, mas pode ser CaseNumber.
    //addCheckbox -> Caso marcado como True valida que campos Checkbox adicionado tem sido marcados (TRUE).
    
    @AuraEnabled (Cacheable=true)
    public static Result checkEmptyFields(Id recordId, String fieldsetName, String keyField, Boolean addCheckbox, Boolean fromFlow) {
        //Get ObjectType by Id
        Schema.SObjectType sobjectType = recordId.getSObjectType();
        String sobjectName = sobjectType.getDescribe().getName();
        //Get FieldSet and Fields
        Schema.DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(sobjectName).getDescribe();
        Schema.FieldSet fs = objResult.fieldSets.getMap().get(fieldsetName);
        List<Schema.FieldSetMember> fields = fs?.getFields();

        if(fields == null) {
            if(fromFlow) {
                Result resErro = new Result(true, 'Erro: Fieldset não encontrado ou sem campos');
                resErro.hasError = true;
                resErro.erroMsg = 'Erro: Fieldset não encontrado ou sem campos';
                return resErro;
            } else {
                throw new CheckEmptyFieldsException('Erro: Fieldset não encontrado ou sem campos');
            }
        }

        Boolean keyInFieldset = false;
        
        //Build query
        String queryTxt = 'SELECT ';
        for(Schema.FieldSetMember f1 :fields) {
            queryTxt += f1.getFieldPath() + ', ';
            //Valida que o keyfield foi adicionado ao fielset
            if(f1.getFieldPath() == keyField) {
                keyInFieldset = true;
            }
        }
        queryTxt += ' Id FROM ' + sobjectName + ' WHERE Id = :recordId';

        if(!keyInFieldset) {
            if(fromFlow) {
                return new Result(true, 'Erro: Adicione o campo de nome do registro chave ao Fielset');
            } else {
                throw new CheckEmptyFieldsException('Erro: Adicione o campo de nome do registro chave ao Fielset');
            }
        }

        SObject obj = Database.query(queryTxt);

        //Check empty fields
        List<String> emptyFields = new List<String>();
        for(Schema.FieldSetMember f2 :fields) {
            if(String.valueOf(f2.getType()) != 'BOOLEAN') {
                if(obj.get(f2.getFieldPath()) == null) {
                    emptyFields.add((String)f2.getLabel());
                }
            }

            if(String.valueOf(f2.getType()) == 'BOOLEAN' && addCheckbox) {
                if(obj.get(f2.getFieldPath()) == false) {
                    emptyFields.add((String)f2.getLabel());
                }
            }

        }

        return buildResult(emptyFields, obj, keyfield);
    }

    public static Result buildResult(List<String> emptyFields, SObject obj, String keyfield) {
        Result res = new Result();
        res.isComplete = emptyFields.isEmpty() ? true : false;
        res.recName = (String)obj.get(keyField);
        res.fields = buildMsg(emptyFields);
        return res;
    }

    public static String buildMsg(List<String> fields) {
        String result;
        if(fields.isEmpty()) {
            result = '';
        } else {
            Integer tam = fields.size();
            result = 'Preenchimento obrigatório: ';
            for(String f : fields){
                result += f;
                result += ', ';
            }
            result = result.removeEnd(', ');
            result += '.';
        }
        return result;
    }

    public class Result {
        @AuraEnabled
        public Boolean isComplete {get;set;}
        
        @AuraEnabled
        public String recName {get;set;}
        
        @AuraEnabled
        public String fields {get;set;}

        @AuraEnabled
        public Boolean hasError {get;set;}

        @AuraEnabled
        public String erroMsg {get;set;}

        public Result(){}

        public Result(Boolean hasError, String erroMsg) {
            this.isComplete = null;
            this.recName = null;
            this.fields = null;
            this.hasError = hasError;
            this.erroMsg = erroMsg;
        }
    }

    public class ResultToFlow {
        @InvocableVariable(label='Objeto completo')
        public Boolean isComplete;

        @InvocableVariable(label='Nome do objeto')
        public String recName;

        @InvocableVariable(label='Campos vazios')
        public String fields;

        @InvocableVariable(label='Tem erro')
        public Boolean hasError;

        @InvocableVariable(label='Mensagem de erro')
        public String erroMsg;

        public ResultToFlow(Result res) {
            this.isComplete = res.isComplete;
            this.recName = res.recName;
            this.fields = res.fields;
            this.hasError = res.hasError;
            this.erroMsg = res.erroMsg;
        }


    }

    public class Request {
        @InvocableVariable(label='Record Id' description='Id do registro a ser checado' required=true)
        public Id recordId;
        
        @InvocableVariable(label='Fieldset Name' description='Nome do fieldset com os campos obrigatórios' required=true)
        public String fieldsetName;
        
        @InvocableVariable(label='Key field' description='Nome do campo que identifica o registro a ser retornado pro Flow' required=true)
        public String keyField;
        
        @InvocableVariable(label='Add checkbox' description='Marca que os campos Booleanos inseridos no fieldset precisam estar TRUE')
        public Boolean addCheckbox;

        public Request(String recordId, String fieldsetName, String keyField, Boolean addCheckbox) {
            this.recordId = recordId;
            this.fieldsetName = fieldsetName;
            this.keyField = keyField;
            this.addCheckbox = addCheckbox;
        }

    }

    public class CheckEmptyFieldsException extends Exception {}

}
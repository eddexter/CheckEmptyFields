@isTest
public class CheckEmptyFieldsControllerTest {
    
    @TestSetup
    static void makeData(){
        Product2 prod = new Product2();
        prod.Name = 'Teste';
        prod.IsActive = true;
        prod.ProductCode = '1234';
        insert prod;
    }


    @isTest
    static void checkEmptyFieldsTest(){
        Product2 prod = [Select Id, Name, IsActive, ProductCode From Product2 Limit 1];

        String errormsg;
        try {
            CheckEmptyFieldsController.checkEmptyFields(prod.Id, 'MyFieldSet', 'Name', false, false);
        } catch (Exception e) {
            errormsg = e.getMessage();
        }

        Assert.areEqual(errormsg, 'Erro: Fieldset não encontrado ou sem campos', 'Erro não capturado');
    }
    
    @isTest
    static void buildResultEmptyTest(){
        Product2 prod = [Select Id, Name, IsActive, ProductCode, Description From Product2 Limit 1];
        
        List<String> emptyFields = new List<String>();
        CheckEmptyFieldsController.Result res = CheckEmptyFieldsController.buildResult(emptyFields, prod, 'Name');

        Assert.isTrue(res.isComplete, 'Objeto incompleto');
    }

    @isTest
    static void buildResultTest(){
        Product2 prod = [Select Id, Name, IsActive, ProductCode, Description From Product2 Limit 1];
        
        List<String> emptyFields = new List<String>();
        emptyFields.add('Description');
        CheckEmptyFieldsController.Result res = CheckEmptyFieldsController.buildResult(emptyFields, prod, 'Name');

        Assert.isFalse(res.isComplete, 'Objeto completo');
    }

    @isTest
    static void checkEmptyFieldsInvocableTest(){
        Product2 prod = [Select Id, Name, IsActive, ProductCode From Product2 Limit 1];

        CheckEmptyFieldsController.Request req = new CheckEmptyFieldsController.Request(prod.Id, 'MyFieldSet', 'Name', false);
        List<CheckEmptyFieldsController.Request> reqs = new List<CheckEmptyFieldsController.Request>();
        reqs.add(req);

        List<CheckEmptyFieldsController.ResultToFlow> res =  CheckEmptyFieldsController.checkEmptyFromFlow(reqs);
        String errormsg = res.get(0).erroMsg;
        
        Assert.areEqual(errormsg, 'Erro: Fieldset não encontrado ou sem campos', 'Erro não capturado');
    }
    
}
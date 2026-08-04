@isTest
private class TestApexClassTest {
    @isTest
    static void testAddNumbers() {
        TestApexClass instance = new TestApexClass();
        Integer result = instance.addNumbers(2, 3);
        System.assertEquals(5, result);
    }
}

@isTest
private class TestApexClassTest {
    @isTest
    static void testAddNumbers() {
        TestApexClass instance = new TestApexClass();
        Integer result = instance.addNumbers(2, 3);
        System.assertEquals(5, result);
    }

    @isTest
    static void testSubtractNumbers() {
        TestApexClass instance = new TestApexClass();
        Integer result = instance.subtractNumbers(5, 3);
        System.assertEquals(2, result);
    }
}

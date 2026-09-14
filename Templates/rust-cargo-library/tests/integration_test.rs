use {{PROJECT_NAME}}::add;

#[test]
fn test_integration() {
    assert_eq!(add(10, 20), 30);
}

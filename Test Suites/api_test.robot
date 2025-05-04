*** Settings ***
Documentation    API tests
#Import Robotframework Library 
Library    RequestsLibrary
Library    JSONLibrary
Library    Collections   
Library    BuiltIn    
Resource	../Resource/Page/api.page.robot  #import page 的 page object

*** Variables ***
${API_BASE_URL}         https://api.practicesoftwaretesting.com
${test_page}    3   #可以任意設定頁數   

*** Test Cases ***
# --- Products API - GET---
GET 所有產品 - 預設分頁
    [Documentation]   GET 所有產品 - 預設分頁
    [Tags]    case1

    Create Session    mysession    ${API_BASE_URL}
    ${response}=    GET On Session    mysession    /products

    # Expected Result: Http Status Code為 200 OK
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200, got ${response.status_code}. Response: ${response.text}

    # Expected Result: JSON 格式, 回應包含 pagination fields
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    current_page
    Dictionary Should Contain Key    ${response_json}    data
    Dictionary Should Contain Key    ${response_json}    from
    Dictionary Should Contain Key    ${response_json}    last_page
    Dictionary Should Contain Key    ${response_json}    per_page
    Dictionary Should Contain Key    ${response_json}    to
    Dictionary Should Contain Key    ${response_json}    total

    # Expected Result: data 欄位是一個非空的array
    Dictionary Should Contain Key    ${response_json}    data
    ${data_list}=    Get Value From Json    ${response_json}    data
    Should Not Be Empty    ${data_list}    msg=Data array should not be empty for default GET products.

GET 單一產品 - 有效 ID
    [Documentation]    GET 單一產品 - 有效 ID, 假設選第一個id去檢查
    [Tags]    case2

    Create Session    mysession    ${API_BASE_URL}
    ${response}=    GET On Session    mysession    /products
    Should Be Equal As Integers    ${response.status_code}    200
    ${response_json}=    Convert String To Json    ${response.text}

    ${data_list}=    Get Value From Json    ${response_json}    data
    #找出第一個id
    ${first_product_id_list}=    Get Value From Json    ${response_json}    $.data[0].id
    ${first_product_id}=    Set Variable    ${first_product_id_list[0]}

    #拿到id後再次呼叫API檢查
    ${response}=    GET On Session    mysession    /products/${first_product_id}
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200 OK, got ${response.status_code}. Response: ${response.text}
    Log To Console    Response Status Code: ${response.status_code}

    ${response_json}=    Convert String To Json    ${response.text}
    Log To Console    Response Body: ${response.text}

    ${returned_id_list}=    Get Value From Json    ${response_json}    id
    ${returned_id}=    Set Variable    ${first_product_id_list[0]}
    Log To Console    Returned ID from response: ${returned_id}, Expected ID from variable: ${first_product_id}

    # 使用 Should Be Equal 進行比較，id應該要相同
    Should Be Equal    ${returned_id}    ${first_product_id}    msg=Returned product ID (${returned_id}) does not match requested ID (${first_product_id}).

GET 特定頁數的產品 - page 參數
    [Documentation]    GET 特定頁數的產品 - page 參數
    [Tags]    case3

    Create Session    mysession    ${API_BASE_URL}
    ${params}=    Create Dictionary    page=${test_page}
    ${response}=    GET On Session    mysession    /products    params=${params}

    # Expected Result: Http Status Code為 200 OK
    Should Be Equal As Integers    ${response.status_code}    200

    # Expected Result: JSON 格式, 回應包含 pagination fields
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    current_page
    Dictionary Should Contain Key    ${response_json}    data
    Dictionary Should Contain Key    ${response_json}    from
    Dictionary Should Contain Key    ${response_json}    last_page
    Dictionary Should Contain Key    ${response_json}    per_page
    Dictionary Should Contain Key    ${response_json}    to
    Dictionary Should Contain Key    ${response_json}    total

    # Expected Result: current_page 欄位的值為 3 (Handle string vs integer)
    Should Be Equal As Integers    ${response_json['current_page']}      ${test_page}    msg=Current page value is incorrect.

    # Expected Result: data 欄位是一個array包含該頁的產品資料
    ${data_list}=    Get Value From Json    ${response_json}    data
    Should Not Be Empty    ${data_list}    msg=Data array should not be empty for this page.

    ${total_page}=    Get Page Total        # 拿到產品total總數
    Should Be Equal    ${response_json['total']}    ${total_page}  

GET 特定價格範圍內的產品 - between 參數 (含分頁)
    [Documentation]    GET 特定價格範圍內的產品 - between 參數 (含分頁)    
    [Tags]    case4
    Create Session    mysession    ${API_BASE_URL}
    Verify All Products In Price Range    10    50  #10,50 也可以設定變數, 可調整


GET 價格範圍內無產品 - between 參數
    [Documentation]    GET 價格範圍內無產品 - between 參數    
    [Tags]    case5
    Create Session    mysession    ${API_BASE_URL}
    Verify All Products In Price Range    99999    1000000    #都可以設定變數, 可調整


GET 產品並按名稱升序排序 (sort=name,asc)
    [Documentation]    GET 產品並按名稱升序排序 (sort=name,asc)
    [Tags]    case6

    Create Session    mysession    ${API_BASE_URL}
    ${params}=    Create Dictionary    sort=name,asc
    ${response}=    GET On Session    mysession    /products    params=${params}

    # Expected Result: Http Status Code為 200 OK
    Should Be Equal As Integers    ${response.status_code}    200

    # Expected Result: JSON 格式
    ${response_json}=    Convert String To Json    ${response.text}

    # Expected Result: data 欄位是一個array
    Dictionary Should Contain Key    ${response_json}    data
    ${data_list}=    Get Value From Json    ${response_json}    data
    Should Not Be Empty    ${data_list}    msg=Data array should not be empty for sorting.

    # Expected Result: data 中其 name 欄位應按字母順序從 A 到 Z 排列
    ${product_names}=    Get Value From Json    ${response_json}    $.data.*.name
    Run Keyword    List Should Be Sorted Alphabetically    ${product_names}

    # Expected Result: total 排序後應還是為總數
    ${total_page}=    Get Page Total        # 拿到產品total總數
    Should Be Equal As Integers    ${response_json['total']}    ${total_page}


GET 產品並按名稱降序排序 (sort=name,desc)
    [Documentation]    GET 產品並按名稱降序排序 (sort=name,desc)
    [Tags]    case7

    Create Session    mysession    ${API_BASE_URL}
    ${params}=    Create Dictionary    sort=name,desc
    ${response}=    GET On Session    mysession    /products    params=${params}

    # Expected Result: Http Status Code為 200 OK
    Should Be Equal As Integers    ${response.status_code}    200

    # Expected Result: JSON 格式
    ${response_json}=    Convert String To Json    ${response.text}

    # Expected Result: data 欄位是一個array
    Dictionary Should Contain Key    ${response_json}    data
    ${data_list}=    Get Value From Json    ${response_json}    data
    Should Not Be Empty    ${data_list}    msg=Data array should not be empty for sorting.

    # Expected Result: data 中其 name 欄位應按字母順序從 Z 到 A 排列
    ${product_names}=    Get Value From Json    ${response_json}    $.data.*.name
    Run Keyword    List Should Be Sorted Alphabetically Reverse    ${product_names}

    # Expected Result: total 排序後應還是為總數
    ${total_page}=    Get Page Total        # 拿到產品total總數
    Should Be Equal As Integers    ${response_json['total']}    ${total_page}


GET 產品並按價格升序排序 (sort=price,asc)
    [Documentation]    GET 產品並按價格升序排序 (sort=price,asc)
    [Tags]    case8

    Create Session    mysession    ${API_BASE_URL}
    ${params}=    Create Dictionary    sort=price,asc
    ${response}=    GET On Session    mysession    /products    params=${params}

    # Expected Result: Http Status Code為 200 OK
    Should Be Equal As Integers    ${response.status_code}    200

    # Expected Result: JSON 格式
    ${response_json}=    Convert String To Json    ${response.text}

    # Expected Result: data 欄位是一個array
    Dictionary Should Contain Key    ${response_json}    data
    ${data_list}=    Get Value From Json    ${response_json}    data
    Should Not Be Empty    ${data_list}    msg=Data array should not be empty for sorting.

    # Expected Result: data array中的產品，其 price 欄位應按數字從低到高排列
    ${product_prices}=    Get Value From Json    ${response_json}    $.data.*.price
    Run Keyword    List Should Be Sorted Numerically    ${product_prices}

    # Expected Result: total 排序後應還是為總數
    ${total_page}=    Get Page Total        # 拿到產品total總數
    Should Be Equal As Integers    ${response_json['total']}    ${total_page}


GET 產品並按價格降序排序 (sort=price,desc)
    [Documentation]    GET 產品並按價格降序排序 (sort=price,desc)
    [Tags]    case9

    Create Session    mysession    ${API_BASE_URL}
    ${params}=    Create Dictionary    sort=price,desc
    ${response}=    GET On Session    mysession    /products    params=${params}

    # Expected Result: Http Status Code為 200 OK
    Should Be Equal As Integers    ${response.status_code}    200

    # Expected Result: JSON 格式
    ${response_json}=    Convert String To Json    ${response.text}

    # Expected Result: data 欄位是一個array
    Dictionary Should Contain Key    ${response_json}    data
    ${data_list}=    Get Value From Json    ${response_json}    data
    Should Not Be Empty    ${data_list}    msg=Data array should not be empty for sorting.

    # Expected Result: data array中的產品，其 price 欄位應按數字從高到低排列
    ${product_prices}=    Get Value From Json    ${response_json}    $.data.*.price
    Run Keyword    List Should Be Sorted Numerically Reverse    ${product_prices}

    # Expected Result: total 排序後應還是為總數
    ${total_page}=    Get Page Total        # 拿到產品total總數
    Should Be Equal As Integers    ${response_json['total']}    ${total_page}

GET 不存在的頁數 - page 參數
    [Documentation]    GET 不存在的頁數 - page 參數
    [Tags]    case12

    Create Session    mysession    ${API_BASE_URL}
    ${params}=    Create Dictionary    page=3333
    ${response}=    GET On Session    mysession    /products    params=${params}

    # Expected Result: Http Status Code為 200 OK (as per JSON, unusual but testing as specified)
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200 even for non-existent page, got ${response.status_code}. Response: ${response.text}

    # Expected Result: JSON 格式
    ${response_json}=    Convert String To Json    ${response.text}
    # Check for presence of pagination fields even if data is empty
    Dictionary Should Contain Key    ${response_json}    current_page
    Dictionary Should Contain Key    ${response_json}    data
    Dictionary Should Contain Key    ${response_json}    from
    Dictionary Should Contain Key    ${response_json}    to
    Dictionary Should Contain Key    ${response_json}    total
    Dictionary Should Contain Key    ${response_json}    last_page
    Dictionary Should Contain Key    ${response_json}    per_page

    # Expected Result: data 欄位是一個空array []
    ${data_list}=     Set Variable       ${response_json['data']}  
    Should Be Empty    ${data_list}    msg=Data array should be empty for non-existent page.

    # Expected Result: total 排序後應還是為總數
    ${total_page}=    Get Page Total        # 拿到產品total總數
    Should Be Equal As Integers    ${response_json['total']}    ${total_page}

    # Expected Result: from, to 為 null
    Should Be Equal    ${response_json['to']}    ${None}
    Should Be Equal    ${response_json['from']}    ${None}

GET 單一產品 - 不存在的 ID
    [Documentation]    GET 單一產品 - 不存在的 ID
    [Tags]    case13

    Create Session    mysession    ${API_BASE_URL}
    ${non_existent_id}=    Set Variable    non_existent_id_12345
    ${response}=    GET On Session    mysession    /products/${non_existent_id}        expected_status=any

    Requested item not found    ${response}


GET 單一產品 - 不支援的格式
    [Documentation]    GET 單一產品 - 不支援的格式
    [Tags]    case14

    Create Session    mysession    ${API_BASE_URL}
    ${product_name}=    Set Variable    Sledgehammer    # Using the example from your documentation
    ${response}=    GET On Session    mysession    /products/${product_name}            expected_status=any

    Requested item not found    ${response}


GET 產品 - 無效的 between 參數格式
    [Documentation]    GET 產品 - 無效的 between 參數格式
    [Tags]    case15

    Create Session    mysession    ${API_BASE_URL}

    ${params_non_numeric}=    Create Dictionary    between=price,abc,xyz
    ${response_non_numeric}=    GET On Session    mysession    /products    params=${params_non_numeric}

    Requested item not found    ${response}


GET 產品 - 無效的 sort 參數格式
    [Documentation]    GET 產品 - 無效的 sort 參數格式
    [Tags]   case16

    Create Session    mysession    ${API_BASE_URL}

    ${params_invalid_direction}=    Create Dictionary    sort=name,up
    ${response_invalid_direction}=    GET On Session    mysession    /products    params=${params_invalid_direction}

    Requested item not found    ${response}

# --- Products API - POST---
POST 產品 - 有效的request object
    [Documentation]    POST 產品 - 有效的request object
    [Tags]    case17

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=return
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!
    ...    email=AAAA@gmail.com

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}

    # Expected Result: Http Status Code為 200 OK (as per JSON, unusual for creation)
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific JSON structure and values
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Item    ${response_json}    name    AA AA
    Dictionary Should Contain Item    ${response_json}    subject    return
    Dictionary Should Contain Item    ${response_json}    message    Quality is not an act, it is a habit. Strive for excellence every day!
    Dictionary Should Contain Item    ${response_json}    email    AAAA@gmail.com
    Dictionary Should Contain Item    ${response_json}    status    NEW
    Dictionary Should Contain Key    ${response_json}    id   
    Dictionary Should Contain Key    ${response_json}    created_at  


POST 產品 - 缺少 object name
    [Documentation]    POST 產品 - 缺少 object name
    [Tags]    case18

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    subject=return
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!
    ...    email=AAAA@gmail.com

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}

    # Expected Result: Http Status Code為 200 OK (as per JSON, unusual for missing field)
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific JSON structure and values (excluding name, but still success)
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Not Contain Key    ${response_json}    name   
    Dictionary Should Contain Item    ${response_json}    subject    return
    Dictionary Should Contain Item    ${response_json}    message    Quality is not an act, it is a habit. Strive for excellence every day!
    Dictionary Should Contain Item    ${response_json}    email    AAAA@gmail.com
    Dictionary Should Contain Item    ${response_json}    status    NEW
    Dictionary Should Contain Key    ${response_json}    id    
    Dictionary Should Contain Key    ${response_json}    created_at  

POST 產品 - 缺少必要 object subject
    [Documentation]    POST 產品 - 缺少必要 object subject
    [Tags]    case19

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!
    ...    email=AAAA@gmail.com

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}        expected_status=any

    # Expected Result: Http Status Code為 422 Unprocessable Entity
    Should Be Equal As Integers    ${response.status_code}    422    msg=Expected 422, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific error message for missing subject
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    subject
    ${subject_error_list}=    Set Variable    ${response_json['subject']}    
    List Should Contain Value    ${subject_error_list}    The subject field is required.


POST 產品 - 缺少必要 object message
    [Documentation]    POST 產品 - 缺少必要 object message
    [Tags]   case20

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=return
    ...    email=AAAA@gmail.com

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}          expected_status=any

    # Expected Result: Http Status Code為 422 Unprocessable Entity
    Should Be Equal As Integers    ${response.status_code}    422    msg=Expected 422, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific error message for missing message
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    message
    ${message_error_list}=    Set Variable    ${response_json['message']}    
    List Should Contain Value    ${message_error_list}    The message field is required.


POST 產品 - 缺少 object email
    [Documentation]    POST 產品 - 缺少 object email
    [Tags]   case21

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=return
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}

    # Expected Result: Http Status Code為 200 OK (as per JSON, unusual for missing field)
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific JSON structure and values (excluding email, but still success)
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Item    ${response_json}    name    AA AA
    Dictionary Should Contain Item    ${response_json}    subject    return
    Dictionary Should Contain Item    ${response_json}    message    Quality is not an act, it is a habit. Strive for excellence every day!
    Dictionary Should Not Contain Key    ${response_json}    email   
    Dictionary Should Contain Item    ${response_json}    status    NEW
    Dictionary Should Contain Key    ${response_json}    id    
    Dictionary Should Contain Key    ${response_json}    created_at 


POST 產品 - email 格式無效
    [Documentation]    POST 產品 - email 格式無效
    [Tags]    case22

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=return
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!
    ...    email=aa.com    # 無效的格式

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}      expected_status=any

    # Expected Result: Http Status Code為 422 Unprocessable Entity
    Should Be Equal As Integers    ${response.status_code}    422    msg=Expected 422, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific error message for invalid email format
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    email
    ${email_error_list}=    Set Variable    ${response_json['email']}  
    List Should Contain Value    ${email_error_list}    The email field must be a valid email address.


POST 產品 - object為錯誤的資料型別 - subject 為數字
    [Documentation]    POST 產品 - object為錯誤的資料型別 - subject 為數字
    [Tags]    case23

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=${123}    #故意輸入數字int
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!
    ...    email=AAAA@gmail.com

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}          expected_status=any

    # Expected Result: Http Status Code為 422 Unprocessable Entity
    Should Be Equal As Integers    ${response.status_code}    422    msg=Expected 422, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific error message for wrong subject type
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    subject
    ${subject_error_list}=    Set Variable    ${response_json['subject']} 
    List Should Contain Value    ${subject_error_list}    The subject field must be a string.


POST 產品 - object為錯誤的資料型別 - message 為布林值
    [Documentation]    POST 產品 - object為錯誤的資料型別 - message 為布林值
    [Tags]    case24

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=return
    ...    message=${TRUE}    #故意用布林type
    ...    email=AAAA@gmail.com

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}          expected_status=any

    # Expected Result: Http Status Code為 422 Unprocessable Entity
    Should Be Equal As Integers    ${response.status_code}    422    msg=Expected 422, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific error message for wrong message type
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    message
    ${message_error_list}=    Set Variable    ${response_json['message']} 
    List Should Contain Value    ${message_error_list}    The message field must be a string.


POST 產品 - 包含非預期 object
    [Documentation]    POST 產品 - 包含非預期 object
    [Tags]   case25

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary
    ...    name=AA AA
    ...    subject=return
    ...    message=Quality is not an act, it is a habit. Strive for excellence every day!
    ...    email=AAAA@gmail.com
    ...    mood=happy    # 非預期的key,value (有些api可能不支援這樣,所以需要測試)

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}

    # Expected Result: Http Status Code為 200 OK (as per JSON)
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200, got ${response.status_code}. Response: ${response.text}

    # Expected Result: 加入非預期 object 不影響post結果
    # Expected Result: Specific JSON structure and values (ignoring unexpected field)
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Item    ${response_json}    name    AA AA
    Dictionary Should Contain Item    ${response_json}    subject    return
    Dictionary Should Contain Item    ${response_json}    message    Quality is not an act, it is a habit. Strive for excellence every day!
    Dictionary Should Contain Item    ${response_json}    email    AAAA@gmail.com
    Dictionary Should Contain Item    ${response_json}    status    NEW
    Dictionary Should Contain Key    ${response_json}    id  
    Dictionary Should Contain Key    ${response_json}    created_at 
    Dictionary Should Not Contain Key    ${response_json}    mood    #不該出現


POST 產品 - Empty Request Body
    [Documentation]    POST 產品 - Empty Request Body
    [Tags]    case26

    Create Session    mysession    ${API_BASE_URL}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${request_body}=    Create Dictionary    # Creates an empty {} JSON body

    ${response}=    POST On Session    mysession    /messages    json=${request_body}    headers=${headers}          expected_status=any

    # Expected Result: Http Status Code為 422 Unprocessable Entity
    Should Be Equal As Integers    ${response.status_code}    422    msg=Expected 422, got ${response.status_code}. Response: ${response.text}

    # Expected Result: Specific error messages for missing required fields
    ${response_json}=    Convert String To Json    ${response.text}
    Dictionary Should Contain Key    ${response_json}    subject
    ${subject_error_list}=    Set Variable    ${response_json['subject']} 
    List Should Contain Value    ${subject_error_list}    The subject field is required.

    Dictionary Should Contain Key    ${response_json}    message
    ${message_error_list}=    Set Variable    ${response_json['message']} 
    List Should Contain Value    ${message_error_list}    The message field is required.



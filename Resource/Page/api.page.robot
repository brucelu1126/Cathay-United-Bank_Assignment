*** Settings ***
Documentation	
...     		可以重複呼叫使用的API可以組合在這
Library     JSONLibrary
Library     RequestsLibrary

*** Keywords ***
#類似Function 寫好後可以重複呼叫
Get Page Total
    Create Session    mysession    ${API_BASE_URL}
    ${response}=    GET On Session    mysession    /products
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected 200, got ${response.status_code}. Response: ${response.text}
    # 設定 total 為變數
    ${response_json}=    Convert String To Json    ${response.text}
    ${total}=    Get From Dictionary    ${response_json}    total
    ${total_page}=   Convert To Integer     ${total}
    [Return]     ${total_page} 

List Should Be Sorted Alphabetically
    [Arguments]    ${input_list}
    ${sorted_list}=    Evaluate    sorted(${input_list})
    Should Be Equal    ${input_list}    ${sorted_list}    msg=List is not sorted alphabetically.

List Should Be Sorted Alphabetically Reverse
    [Arguments]    ${input_list}
    ${sorted_list}=    Evaluate    sorted(${input_list}, reverse=True)
    Should Be Equal    ${input_list}    ${sorted_list}    msg=List is not sorted reverse alphabetically.

List Should Be Sorted Numerically
    [Arguments]    ${input_list}
    ${numeric_list}=    Create List
    FOR    ${item}    IN    @{input_list}
        ${numeric_item}=    Convert To Number    ${item}
        Append To List    ${numeric_list}    ${numeric_item}
    END
    ${sorted_list}=    Evaluate    sorted(${numeric_list})
    Should Be Equal    ${numeric_list}    ${sorted_list}    msg=List is not sorted numerically.

List Should Be Sorted Numerically Reverse
    [Arguments]    ${input_list}
    ${numeric_list}=    Create List
    FOR    ${item}    IN    @{input_list}
        ${numeric_item}=    Convert To Number    ${item}
        Append To List    ${numeric_list}    ${numeric_item}
    END
    ${sorted_list}=    Evaluate    sorted(${numeric_list}, reverse=True)
    Should Be Equal    ${numeric_list}    ${sorted_list}    msg=List is not sorted reverse numerically.

# 檢查price是否都在range內, 正確性
Verify All Products In Price Range
    [Arguments]    ${min_price}    ${max_price}
    ${page}=    Set Variable    1
    ${all_prices}=    Create List 

    WHILE    True
        ${params}=    Create Dictionary    between=price,${min_price},${max_price}    page=${page}
        ${response}=    GET On Session    mysession    /products    params=${params}
        Should Be Equal As Integers    ${response.status_code}    200

        ${json}=    Convert String To Json    ${response.text}
        Dictionary Should Contain Key    ${json}    data
        ${page_prices}=    Get Value From Json    ${json}    $.data[*].price

        FOR    ${price}    IN    @{page_prices}
            Append To List    ${all_prices}    ${price}
        END

        ${received_total}=    Get Length    ${all_prices}
        ${total}=    Get From Dictionary    ${json}    total

         # 如果 total = 0，直接跳出（表示沒有產品符合此範圍）
        Run Keyword If    '${total}' == '0'
        ...    Log To Console    ⚠ No products found in the price range [${min_price}, ${max_price}]. Skipping verification.
        ...    RETURN

        Log To Console    → Collected ${received_total} / ${total} prices so far...

        Run Keyword If    ${received_total} >= ${total}    Exit For Loop
        ${page}=    Evaluate    ${page} + 1
    END

    Log To Console    Total ${received_total} prices collected.

    FOR    ${price}    IN    @{all_prices}
        Should Be True    ${price} >= ${min_price}    msg=Price ${price} < ${min_price}
        Should Be True    ${price} <= ${max_price}    msg=Price ${price} > ${max_price}
    END

#404
Requested item not found
    [Arguments]    ${response}  
    # Expected Result: Http Status Code為 404 Not Found
    Should Be Equal As Integers    ${response.status_code}    404    msg=Expected 404 Not Found, got ${response.status_code}. Response: ${response.text}

    # Expected Result: JSON 格式
    ${response_json}=    Convert String To Json    ${response.text}

    # Expected Result: {"message":"Requested item not found"}
    Dictionary Should Contain Item    ${response_json}    message    Requested item not found
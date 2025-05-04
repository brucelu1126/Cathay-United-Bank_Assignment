*** Settings ***

Documentation	Template for calling API
...     		Install library with the following command
...     		pip install robotframework-requests
...				pip install robotframework-jsonLibrary

Library     JSONLibrary
Library     RequestsLibrary
Library     api_function.py		${ENV}
Resource	    ${CURDIR}/../keywords/common.keywords.robot
Resource	    ${CURDIR}/../resources/common.data.robot
Resource	    ${CURDIR}/../templates/gmail.templates.robot
Resource	    ${CURDIR}/../keywords/hkid.keywords.robot
Resource	    ${CURDIR}/../keywords/language.keywords.robot

*** Variables ***
${login_session} 	login_session
${request_session} 	request_session
${URL_API_DOMAIN}	.api.${ENV}.onedegree.hk
#Vet api
${URL_API_VET} 	https://admin:onedegree@vet-api.${ENV}.onedegree.hk
${URI_VET_cert}				/vet-certs/$cert_id
${URI_VET_cert_submit}		/vet-certs/$cert_id/submit
${URI_VET_expenses}		    /vet-expenses
${URI_VET_diagnoses}		/vet-diagnoses
#Pet customer web app api
${URL_API} 		https://admin:onedegree@api.${ENV}.onedegree.hk/
${URI_login} 						/login
${URI_guest_login} 			        /guest-login
${URI_user_profile_get} 			/me
${URI_user_profile_update} 			/me
${URI_password_update}	      		/me/password
${URI_verify_email_intimation}	    /verify-email-intimation
${URI_verify_email}	   				/verify-email

${URI_policy_detail_get} 			/pets/policies/$policy_id
${URI_promo_detail_get}				/pets/check-promotions
${URI_policy_create}	            /pets/policies
${URI_underwrite}	                /pets/policies/$policy_id/underwrite
${URI_policy_pay}	      			/pets/policies/$policy_id/pay
${URI_policy_cancel}			    /pets/policies/$policy_id/cancel
${URI_policy_list}	                /pets/policies
${URI_policy_save_quote}            /pets/policies/quotation-intimation

${URI_create_claims}				/pets/claims
${URI_upload_file}				    /pets/claims/$claim_id/attachments
${URI_claim_submit}					/pets/claims/$claim_id/submit
${URI_vet_detail_get}				/vets
${URI_clinic_vet_certs} 	     	/vet-certs
${URI_clinic_detail_get} 			/vet-clinics/$clinic_id
${URI_clinic_detaillist_get} 		/vet-clinics
${URI_clinic_profile_get}			/me
${URI_policy_save_quoteD3D7}        qa/pets/policies/$policy_id/save_quote
${URI_policy_back_CreateTime}       qa/pets/policies/modify-policy-create-time/$policy_id/$back_days
${URI_payment_schedule_get}			qa/pets/policies/$policy_id/payment-schedule
${URI_payment_cancellation_get}		qa/pets/policies/$policy_id/cancellation
${URI_payment_fail_update}			qa/pets/policies/$policy_id/payment-schedule/$installment_id/capture-failed
${URI_payment_status_update}		qa/pets/policies/$policy_id/annual_limits/
${URI_policy_status_update} 		qa/pets/policies/$policy_id/$back_days
${URI_claim_status_update} 			qa/pets/claims/$claim_id/modify-status
${URI_settlement_status_update} 	qa/pets/claims/modify-settlement-status
${URI_claim_flags_get}				qa/pets/claims/$claim_id/flags
${URI_promo_code_create}			/qa/pets/promo_codes

${URI_annual_limit_update}
${URI_paymentcard_create}	        /payment-cards
${URI_paymentcard_list_get}	        /payment-cards

${json_file_promo}					./json/promo_$name.json
${CSRF_token} 	1

*** Keywords ***
Init Login Session
	${dict_cookie}=  Create Dictionary   CSRF-TOKEN=${CSRF_token} 	path=/	domain=${URL_API_DOMAIN}
	RequestsLibrary.Create Session 	alias=${login_session} 	url=${URL_API}  	verify=${False} 	timeout=60 	disable_warnings=0 	cookies=${dict_cookie}

Call API Login 	
	[Arguments]	 ${username}	 ${password}
	Init Login Session
    ${body}=	Create Dictionary   email=${username}	password=${password}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}

    ${response}= 	RequestsLibrary.Post Request 	${login_session}	${URI_login}	headers=${headers} 	data=${body}
	Response Status Should Be 200 OK 	${response}
	${access_token}= 	JSONLibrary.Get Value From Json 	${response.headers} 	$..Set-Cookie
	${access_token}=	Convert To String	${access_token}
	${access_token}=	Fetch From Right	${access_token}	ACCESS_TOKEN=
	${access_token}=	Fetch From Left	${access_token}	; Expires
	${access_token}= 	Set Variable 	${access_token}
	[Return]	${access_token}

Init Request Session
	[Arguments]	${access_token}
    ${dict_cookie}=  Create Dictionary   ACCESS_TOKEN=${access_token} 	CSRF-TOKEN=${CSRF_token} 	path=/	domain=${URL_API_DOMAIN}
	RequestsLibrary.Create Session 	alias=${request_session} 	url=${URL_API} 	cookies=${dict_cookie}		verify=${False} 	timeout=60   

#Guest Login
Call API Guest Login
	Init Login Session
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	 Origin=${URL_API_DOMAIN}
	${response}= 	RequestsLibrary.Post Request 	${login_session}	${URI_guest_login}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Guest Login : ${response.json()}
	Response Status Should Be 200 OK 	${response}

#Create policy
Call API Create a Policy
	[Arguments]	 ${dict_data}
	Call API Guest Login
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${response}= 	RequestsLibrary.Post Request 	${login_session}	${URI_policy_create}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Create a Policy : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${policy_id}= 	Get Value From Json 	${response.json()} 	$..data[:].id
	Log to console 	[ RESPONSE ]Policy ID : @{policy_id}[0]
	[Return]	@{policy_id}[0]

Call API to Save Quote
    [Arguments]    ${policy_id}    ${email-address}
	${formatted_policy_id}=    BuiltIn.Catenate    {"policy_id": ${policy_id}	}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${response}= 	RequestsLibrary.Post Request 	${login_session}	${URI_policy_save_quote}	data=${formatted_policy_id}    headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API to Save Quote : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	Log to console 	[ RESPONSE ]Email address is : ${email-address}

Call API Create Second Policy
	[Arguments]	 ${login_username}  ${login_password}  ${dict_data}
	Call API Login  ${login_username}  ${login_password}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${response}= 	RequestsLibrary.Post Request 	${login_session}	${URI_policy_create}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Create a Policy : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${policy_id}= 	Get Value From Json 	${response.json()} 	$..data[:].id
	Log to console 	[ RESPONSE ]Policy ID : @{policy_id}[0]
	[Return]	@{policy_id}[0]

#Create claim 
Call API Create a Claim
	[Arguments]	 ${access_token}    ${dict_data}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_create_claims}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Create a Claim : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${text}=  Set Variable  ${response.json()}
	${claim_id}= 	Get Value From Json 	${response.json()} 	$..data[:].id
	${claim_No}= 	Get Value From Json 	${response.json()} 	$..data[:].name
	Log to console 	[ RESPONSE ]Claim ID : @{claim_id}[0] & Claim NO : @{claim_No}[0]
	[Return]	@{claim_id}[0]		@{claim_No}[0]

#multipart/form-data
Call API Claim URI Upload Receipt
	[Arguments]	  ${login_username} 	${claim_id}
	post_login    ${login_username}
	post_attachments	${claim_id}		receipt

#multipart/form-data
Call API Claim URI Upload Diagnosis Report
	[Arguments]	  ${login_username} 	${claim_id}
	post_login    ${login_username}
	post_attachments	${claim_id}		diagnosis_report

Call API Claim URI Upload Signature
	[Arguments]	  ${login_username} 	${claim_id}
	post_login    ${login_username}
	post_attachments	${claim_id}		signature	

Call API Claim URI Upload HKID
	[Arguments]	  ${login_username} 	${claim_id}
	post_login    ${login_username}
	post_attachments	${claim_id}		hkid

Call API Claim URI Upload Bank Statement
	[Arguments]	  ${login_username} 	${claim_id}
	post_login    ${login_username}
	post_attachments	${claim_id}		bank_statement

Call API Submit a Claim
	[Arguments]	 ${access_token}	${claim_id}
	Init Request Session 	${access_token}
	${claim_id}= 	Convert To String 	${claim_id}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${URI_claim_submit}= 	Replace String 	${URI_claim_submit}  	$claim_id 	${claim_id}
	${dict_data}=	Create Dictionary   claim_id=${claim_id}
	${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_claim_submit}		data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Submit a Claim : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${text}=  Set Variable  ${response.json()}

#Underwrite policy
Call API Underwrite
	[Arguments]	${policy_id}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${dict_data}=	Create Dictionary   policy_id=${policy_id}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_underwrite}= 	Replace String 	${URI_underwrite}  	$policy_id 	${policy_id}
    ${response}= 	RequestsLibrary.Post Request 	${login_session} 	${URI_underwrite}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Underwrite : ${response.json()}
	Response Status Should Be 200 OK 	${response}

#Create payment card
Call API Create Payment Card
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${dict_data}=	Create Dictionary   stripe_token=tok_mastercard
    ${response}= 	RequestsLibrary.Post Request 	${login_session} 	${URI_paymentcard_create}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Create Payment Card : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${payment_card_id}= 	Get Value From Json 	${response.json()} 	$..data[:].id
	Log to console 	[ RESPONSE ]Policy ID : @{payment_card_id}[0]
	[Return]	@{payment_card_id}[0]

#Pay for a pet policy
Call API Pay For Policy
	[Arguments]	${policy_id}	${payment_card_id}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
  	${dict_data}=	Create Dictionary   payment_card_id=${payment_card_id}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_policy_pay}= 	Replace String 	${URI_policy_pay}  	$policy_id 	${policy_id}
    ${response}= 	RequestsLibrary.Post Request 	${login_session} 	${URI_policy_pay}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Pay For Policy : ${response.json()}
	Response Status Should Be 200 OK 	${response}

#Update password
Call API Update Policy Password
	[Arguments]	${old_password}		${password}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${dict_data}=	Create Dictionary   old_password=${old_password}	password=${password}
    ${response}= 	RequestsLibrary.Post Request 	${login_session} 	${URI_password_update}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Update Policy Password : ${response.json()}
	Response Status Should Be 200 OK 	${response}

#Send Account Verification Email
Call API Send Account Verification Email
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Post Request 	${login_session} 	${URI_verify_email_intimation}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Send Account Verification Email : ${response.json()}
	Response Status Should Be 200 OK 	${response}

#Verify email
Call API Verify Email
	[Arguments]		${access_token}		${token}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${dict_data}=	Create Dictionary   token=${token}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_verify_email}		data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Verify Email : ${response.json()}
	Response Status Should Be 200 OK 	${response}

Call API Update claim status
	[Arguments]	${access_token}	${status}	${claim_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${dict_data}=	Create Dictionary   status=${status}
	${claim_id}= 	Convert To String 	${claim_id}
	${URI_claim_status_update}= 	Replace String 	${URI_claim_status_update}  	$claim_id 	${claim_id}
    ${response}= 	RequestsLibrary.Patch Request 	${request_session} 	${URI_claim_status_update}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Update Claim Status Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${text}=  Set Variable  ${response.json()}

Call API UPDATE Policy Prefered Language
	[Arguments]	${access_token}  ${langauge}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json	  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${dict_data}=	Create Dictionary   language=${langauge}	
    ${response}= 	RequestsLibrary.Patch Request 	${request_session} 	${URI_user_profile_update}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]UPDATE Policy Prefered Language : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${text}=  Set Variable  ${response.json()}

Call API Update settlement status
	[Arguments]	${access_token}		${status}	${claim_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${claim_id}= 	convert to integer 	${claim_id}
    ${dict_data}=	Create Dictionary   claim_id=${claim_id}	status=${status}	
    ${response}= 	RequestsLibrary.Patch Request 	${request_session} 	${URI_settlement_status_update}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Update Settlement Status Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}

Call API Update policy status
	[Arguments]	${access_token}		${back_days}	${policy_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${dict_data}=	Create Dictionary   back_days=${back_days}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_policy_status_update}= 	Replace String 	${URI_policy_status_update}  	$policy_id 	${policy_id}
	${URI_policy_status_update}= 	Replace String 	${URI_policy_status_update}  	$back_days 	${back_days}
    ${response}= 	RequestsLibrary.Patch Request 	${request_session} 	${URI_policy_status_update}	 data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Update Policy Status Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}

Call API Update policy CreateTime
	[Arguments]	${access_token}		${policy_id}	${back_days}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${dict_data}=	Create Dictionary   back_days=${back_days}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_policy_back_CreateTime}= 	Replace String 	${URI_policy_back_CreateTime}  	$policy_id 	${policy_id}
	${URI_policy_back_CreateTime}= 	Replace String 	${URI_policy_back_CreateTime}  	$back_days 	${back_days}
    ${response}= 	RequestsLibrary.Patch Request 	${request_session} 	${URI_policy_back_CreateTime}	 data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Update Policy Status Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}

Call API SaveQuote D3D7
	[Arguments]	${access_token}		${policy_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_policy_save_quoteD3D7}= 	Replace String 	${URI_policy_save_quoteD3D7}  	$policy_id 	${policy_id}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_policy_save_quoteD3D7}	 headers=${headers} 	
	Response Status Should Be 200 OK 	${response}
	Log to console 	[ RESPONSE ]Update Payment Status Response : ${response.json()}
	${status}=       Get Value From Json  ${response.json()}  $.status
	Should Be Equal		${status}[0]	${0}

Call API Get Policy Detail by ID
	[Arguments]	${access_token} 	${policy_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_policy_detail_get}= 	Replace String 	${URI_policy_detail_get}  	$policy_id 	${policy_id}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_policy_detail_get}	headers=${headers} 	
	Log to console 	[ RESPONSE ]GET Policy Detail Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]	${response}

Call API Get Clinic Detail List
	[Arguments]	${access_token}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json  CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_clinic_detaillist_get}	headers=${headers} 	
	Log to console 	[ RESPONSE ]GET Clinic Detail List Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]	${response}

Call API Get Payment Schedule
	[Arguments]  ${access_token}	${policy_id}
	Init Request Session 	${access_token}
	## Need to check why should not add "Content-Type=application/json" in headers
	# ${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${headers}= 	Create Dictionary 	Accept=application/json   CSRF-TOKEN=${CSRF_token}
    ${policy_id}= 	Convert To String 	${policy_id}
	${URI_payment_schedule_get}= 	Replace String 	${URI_payment_schedule_get}  	$policy_id 	${policy_id}
	${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_payment_schedule_get}	 headers=${headers} 	
	Log to console 	[ RESPONSE ]Get Payment Schedule Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]  ${response}

Call API Get Policy Cancellation
	[Arguments]  ${access_token}	${policy_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${policy_id}= 	Convert To String 	${policy_id}
	${URI_payment_cancellation_get}= 	Replace String 	${URI_payment_cancellation_get}  	$policy_id 	${policy_id}
	${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_payment_cancellation_get}	 headers=${headers} 	
	Log to console 	[ RESPONSE ]Get Policy Cancellation Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]  ${response}

Call API Get Claim Flags
	[Arguments]  ${access_token}	${claim_id}
	Init Request Session 	${access_token}
	## Need to check why should not add "Content-Type=application/json" in headers
	# ${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${headers}= 	Create Dictionary 	Accept=application/json   CSRF-TOKEN=${CSRF_token}
	${claim_id}= 	Convert To String 	${claim_id}
	${URI_claim_flags_get}= 	Replace String 	${URI_claim_flags_get}  	$claim_id 	${claim_id}
	${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_claim_flags_get}	 headers=${headers} 	
	Log to console 	[ RESPONSE ]Get Claim Flags Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]  ${response}

Call API Get Vet Details
	[Arguments]  ${access_token}	${vet_id}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${vet_id}= 	Convert To String 	${vet_id}
	${params}= 	Create Dictionary 	vet_id=${vet_id}
	${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_vet_detail_get}	 headers=${headers}	 params=${params}  	
	Log to console 	[ RESPONSE ]Get Vet Details Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]  ${response}

Call API Check Promotion Details
	[Arguments]  ${access_token}	${promo_code}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${promo_code_list}=	Create List		${promo_code}
	${body}= 	Create Dictionary 	promo_codes=${promo_code_list}
	${response}= 	RequestsLibrary.Post Request	${request_session} 	${URI_promo_detail_get}	 json=${body}	headers=${headers}	
	Log to console 	[ RESPONSE ]Check Promotion Details: ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]  ${response}

Call API Get Payment Card Details
	[Arguments]  ${access_token}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${response}= 	RequestsLibrary.Get Request	${request_session} 	${URI_paymentcard_list_get}	 headers=${headers}	
	Log to console 	[ RESPONSE ]Get Payment Card: ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]  ${response}

Call API Update payment status
	[Arguments]	${access_token}		${policy_id}	${installment_id}	
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${policy_id}= 	Convert To String 	${policy_id}
	${installment_id}= 	Convert To String 	${installment_id}
	${URI_payment_status_update}= 	Replace String 	${URI_payment_status_update}  	$policy_id 	${policy_id}
	${URI_payment_status_update}= 	Replace String 	${URI_payment_status_update}  	$installment_id 	${installment_id}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_payment_status_update}	 headers=${headers} 	
	Log to console 	[ RESPONSE ]Update Payment Status Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${payment_status}=       Get Value From Json  ${response.json()}  $.data.status
	# Should Be Equal		${payment_status}[0]	done

Call API Captured Payment Failed
	[Arguments]	${access_token}		${policy_id}	${installment_id}	
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${policy_id}= 	Convert To String 	${policy_id}
	${installment_id}= 	Convert To String 	${installment_id}
	${URI_payment_fail_update}= 	Replace String 	${URI_payment_fail_update}  	$policy_id 	${policy_id}
	${URI_payment_fail_update}= 	Replace String 	${URI_payment_fail_update}  	$installment_id 	${installment_id}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_payment_fail_update}	 headers=${headers} 	
	# Log to console 	[ RESPONSE ]Update Payment Status Response : ${response.json()}
	# Response Status Should Be 200 OK 	${response}
	# ${payment_status}=       Get Value From Json  ${response.json()}  $.data.status
	# Should Be Equal		${payment_status}[0]	done

Call API Update referral policy annual limit
	[Arguments]	${access_token}		${policy_id}
	[Documentation]     Simulate batch process for Policy: Check Annual Limit
    ...		BE will check if Referral's or Referee's cool off period ends and status is not cancelled.
	...		If YES, will add referral bonus to annual limit
	...		If YES, do nothing
    ...    	Parameters: Policy ID (Referral or Referee)
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_annual_limit_update}= 	Replace String 	${URI_payment_status_update}  	$policy_id 	${policy_id}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_annual_limit_update}	 headers=${headers} 	
	Response Status Should Be 200 OK 	${response}
	Log to console 	[ RESPONSE ]Update Payment Status Response : ${response.json()}
	${status}=       Get Value From Json  ${response.json()}  $.status
	Should Be Equal		${status}[0]	${0}

Call API create promo code    
	[Arguments]  ${promo_code} 
	${access_token}=    	Call API Login  ${effective_username}   ${effective_password}
	${json_file_promo}=		Replace String  ${json_file_promo}   $name 	${promo_code} 	
	${dict_data}=  Load JSON From File  ${json_file_promo}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_promo_code_create}	data=${dict_data}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Create Promotion Code Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}

Call API get policy list  
	[Arguments]  ${access_token} 
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_policy_list}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Get Policy List Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]	${response}

Call API Cancel a Policy
	[Arguments]  ${access_token}  ${policy_id}  ${cancel_reason}
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	${dict_data}=	Create Dictionary   cancel_reason=${cancel_reason}
	${policy_id}= 	Convert To String 	${policy_id}
	${URI_policy_cancel}= 	Replace String 	${URI_policy_cancel}  	$policy_id  ${policy_id}
	${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_policy_cancel}  data=${dict_data} 	headers=${headers} 	
	Log to console 	[ RESPONSE ]Get Policy List Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]	${response}

Get Claim ID from URL
	${current_URL}= 	Get Location
	${claim_id}=	Fetch From Right	${current_URL}	/
	[Return]	${claim_id}

Get Policy ID from URL
	${current_URL}= 	Get Location
	${policy_id}=	Fetch From Right	${current_URL}	/
	[Return]	${policy_id}

Call API Get Policy ID 
	[Arguments]  ${access_token} 
	Init Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_policy_list}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Get Policy List Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	${policy_id}= 	Get Value From Json 	${response.json()} 	$..data[:].id
	Log to console 	[ RESPONSE ]Policy ID : @{policy_id}[0]
	[Return]	@{policy_id}[0]

Response Status Should Be 200 OK
	[Arguments]	${response}
	Should Be Equal As Integers 	200 	${response.status_code}

UPDATE Policy Status To Effective
	[Arguments]	${username}	 ${password}	${policyNO}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update policy status    ${access_token} 	60   ${policyNO}

UPDATE Policy Status To Expired
	[Arguments]	${username}	 ${password}	${policyNO}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update policy status    ${access_token} 	500   ${policyNO}

UPDATE Policy Backdate
	[Arguments]	${username}	 ${policyNO}	${back_days}
    ${access_token}=    Call API Login  ${username}   ${effective_password} 
    Call API Update policy status    ${access_token} 	${back_days}   ${policyNO}

UPDATE Policy Backdate by SaveQuote
	[Arguments]	${username}	 ${policyNO}	${back_days}
    ${access_token}=    Call API Login  ${username}   ${effective_password} 
    Call API Update policy CreateTime    ${access_token}	${policyNO}	 ${back_days} 
	Log to console 	[ RESPONSE ]UPDATE Policy Backdate by SaveQuote Policy ID : ${policyNO}

UPDATE Policy by SaveQuote D3D7
	[Arguments]	${username}	 ${policyNO}
    ${access_token}=    Call API Login  ${username}   ${effective_password} 
    Call API SaveQuote D3D7    ${access_token}	${policyNO}
	Log to console 	[ RESPONSE ]UPDATE Policy Backdate by SaveQuote Policy ID : ${policyNO}

UPDATE Claim Status To Approved
	[Arguments]	${username}	 ${password}	${claimNo}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update claim status    ${access_token} 	approved   ${claimNo}

UPDATE Claim Status To Declined
	[Arguments]	${username}	 ${password}	${claimNo}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update claim status    ${access_token} 	rejected   ${claimNo}

UPDATE Claim Status To Settled
	[Arguments]	${username}	 ${password}	${claimID}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update settlement status    ${access_token} 	processing 	${claimID}	 
    Call API Update settlement status    ${access_token} 	success 	${claimID}	 

UPDATE Policy Prefered Language
	[Arguments]	${username}   ${password}
	
	${updatelanguage}=  Run Keyword If  '${language}'=='${hk}'         Set Variable     zh_HK
    ...   ELSE      Set Variable     en_US	
	
	${access_token}=    Call API Login  ${username}   ${password} 
	Call API UPDATE Policy Prefered Language    ${access_token}  ${updatelanguage}

GET Policy Detail by ID
	[Arguments]	${username}	 ${password}	${policyID}
    ${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Policy Detail by ID    ${access_token} 	${policyID}
	[Return]	${response}

GET Policy List
	[Arguments]	${username}	 ${password}
    ${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Policy List    ${access_token}
	[Return]	${response}

GET Clinic Detail List
	[Arguments]	${username}	 ${password}
    ${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Clinic Detail List    ${access_token}
	[Return]	${response}

Get Payment Schedule by Policy ID
	[Arguments]  ${username}	 ${password}	${policy_id}
    ${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Payment Schedule    ${access_token}	${policy_id}
	[Return]	${response}

Get Claim Flag by Claim ID
	[Arguments]		${username}		${password}		${claim_id}
	${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Claim Flags  ${access_token}	${claim_id}
	[Return]	${response}

GET Vet Name by Vet ID
	[Arguments]		${username}		${password}		${vet_id}
	${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Vet Details  ${access_token}	${vet_id}
	[Return]	${response}

GET Promotion Details by Promo Code
	[Arguments]		${username}		${password}		${promo_code}
	${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Check Promotion Details  ${access_token}	${promo_code}
	[Return]	${response}

GET Payment Card Details
	[Arguments]		${username}		${password}
	${access_token}=    Call API Login  ${username}   ${password}
	${response}= 	Call API Get Payment Card Details  ${access_token}
	[Return]	${response}

UPDATE Payment Status To Paid
	[Arguments]	 ${username}	 ${password}	${policyID}  ${installmentID}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update payment status    ${access_token} 	${policyID}  ${installmentID}

UPDATE Policy Annual Limit
	[Arguments]	 ${username}	 ${password}	${policyID}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Update referral policy annual limit    ${access_token} 	${policyID}

UPDATE Payment Status To Failed
	[Arguments]	 ${username}	 ${password}	${policyID}  ${installmentID}
    ${access_token}=    Call API Login  ${username}   ${password} 
    Call API Captured Payment Failed    ${access_token} 	${policyID}  ${installmentID}

Cancel A Policy
	[Arguments]  ${username}   ${password}   ${policyID}
	${access_token}=    Call API Login   ${username}   ${password} 
	
	${cancel_reason}  Create Dictionary    
    ${reasons} =    Create List     1
    Set To Dictionary  ${cancel_reason}  cancellation_reason_ids  ${reasons}
	
	Call API Cancel a Policy  ${access_token}  ${policyID}  ${cancel_reason}

#=====================Get Data From Response========================#

Get AVID From Policy Detail Response
	[Arguments]	${response} 
	${value}= 	Get Value From Json 	${response.json()} 	$.data.pet_microchip
	[Return]	@{value}[0]

Get Owner Name From Policy Detail Response
	[Arguments]	${response} 
	${firstname}= 	Get Value From Json 	${response.json()} 	$.data.firstname
	${lastname}= 	Get Value From Json 	${response.json()} 	$.data.lastname
	${ownerName}= 	Set Variable 	@{lastname}[0]${SPACE}@{firstname}[0]
	[Return]	${ownerName}


Get Address From Clinic Detail Response
	[Arguments]	${response}		${clinic_name}=${bypass_claimClinic}
	${namespace}=  Get Namespace  ${clinic_name}
	${clinic_name}=  Remove namespace from key_text  ${clinic_name}
	${address1_json_path}= 	Replace String 	$..data[?(@.name=='$Name')].address1 	$Name 	${clinic_name}
	${address2_json_path}= 	Replace String 	$..data[?(@.name=='$Name')].address2 	$Name 	${clinic_name}
	${address1}= 	Get Value From Json 	${response.json()} 	${address1_json_path}
	${address2}= 	Get Value From Json 	${response.json()} 	${address2_json_path}

	${address_1_value}=  Change Key To Value  @{address1}[0]  ${namespace}
	${address_2_value}=  Change Key To Value  @{address2}[0]  ${namespace}
	${address}= 	Set Variable 	${address_1_value}, ${address_2_value}
	[Return]	${address}

Get Phone Number From Clinic Detail Response
	[Arguments]	${response}		${clinic_name}=${bypass_claimClinic} 
	${clinic_name}=  Remove namespace from key_text  ${clinic_name}
	${json_path}= 	Replace String 	$..data[?(@.name=='$Name')].phone 	$Name 	${clinic_name}
	${phone}= 	Get Value From Json 	${response.json()} 	${json_path}
	[Return]	@{phone}[0]

Get First Vet ID From Clinic Detail Response
	[Arguments]	${response}		${clinic_name}=${bypass_claimClinic} 
	${clinic_name}=  Remove namespace from key_text  ${clinic_name}
	${json_path}= 	Replace String 	$..data[?(@.name=='$Name')].vet_ids		$Name 	${clinic_name}
	${vet_list}= 	Get Value From Json 	${response.json()} 	${json_path}
	${first_vet_ID}= 	Get From List 	@{vet_list}[0]		0  
	[Return]	${first_vet_ID}

Get Vet Name from Vet Detail Response
	[Arguments]	${response}
	${firstname}= 	Get Value From Json 	${response.json()} 	$.data[0].firstname
	${lastname}= 	Get Value From Json 	${response.json()} 	$.data[0].lastname
	${vetName}= 	Set Variable 	Dr. @{firstname}[0]${SPACE}@{lastname}[0]
	[Return]	${vetName}

Get Levy From Payment Schedule Response
	[Arguments]		${response}
	${data}= 	Get Value From Json 	${response.json()} 	$.data  
	${1st_payemnt}=	 Convert To Dictionary  ${data[0]}[0]
	${value}=  	Set Variable  ${1st_payemnt}[levy]
	[Return]	${value}

Get Premium From Payment Schedule Response
	[Arguments]		${response}
	${data}= 	Get Value From Json 	${response.json()} 	$.data  
	${1st_payemnt}=	 Convert To Dictionary  ${data[0]}[0]
	${value}=  	Set Variable  ${1st_payemnt}[premium]
	[Return]	${value}

Get Total Amount From Payment Schedule Response
	[Arguments]		${response}
	${data}= 	Get Value From Json 	${response.json()} 	$.data  
	${1st_payemnt}=	 Convert To Dictionary  ${data[0]}[0]
	${value}=  	Set Variable  ${1st_payemnt}[total_amount]
	[Return]	${value}

Get Policy Cancellation by Policy ID
	[Arguments]  ${username}	 ${password}	${policy_id}
    ${access_token}=    Call API Login  ${username}   ${password}
	${response}=	Call API Get Policy Cancellation	${access_token}	 ${policy_id}
	[Return]	${response}

Get Prepaid Premium From Policy Cancellation
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data.prepaid_premium
	[Return]	@{value}[0]

Get Refund Levy Amount From Policy Cancellation
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data.refund_levy_amount
	[Return]	@{value}[0]

Get Refund Amount From Policy Cancellation
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data.refund_amount
	[Return]	@{value}[0]

Get Cancellation Fee From Policy Cancellation
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data.cancellation_fee
	[Return]	@{value}[0]

Get Flag Code List From Claim Flags
	[Arguments]		${response}
	${source}=  Convert To Dictionary  ${response.json()}
	${data}=    Get From Dictionary  ${source}   data  
	${data}=    Convert To List  ${data}

	${value}=	Create List
	:FOR  ${item}  IN  @{data}	
	\	${code}  Get Value From Json  ${item}  $.code
	\	Append To List  ${value}  ${code}
	\

	[Return]	${value}

Get Flag Reason List From Claim Flags
	[Arguments]		${response}
	${source}=  Convert To Dictionary  ${response.json()}
	${data}=    Get From Dictionary  ${source}   data  
	${data}=    Convert To List  ${data}

	${value}=	Create List
	:FOR  ${item}  IN  @{data}	
	\	${code}  Get Value From Json  ${item}  $.reason
	\	Append To List  ${value}  ${code}
	\

	[Return]	${value}

Get BYPASS Vet Name by Clinic Name
	[Arguments]		${username}		${password}		${clinic_name}=${bypass_claimClinic}
	${response}= 	GET Clinic Detail List	${username}	 	${password}
	${clinic_name_key}=  Remove namespace from key_text     ${clinic_name}
	${vet_id}= 	Get First Vet ID From Clinic Detail Response		${response}		${clinic_name_key}
	${response}= 	GET Vet Name by Vet ID  ${username}	 	${password}		${vet_id}
	${vet_name}= 	Get Vet Name from Vet Detail Response	${response}
	[Return]	${vet_name}

Get Promotion Data
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data[:]
	[Return]	@{value}[0]

Get Billing History Data
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data[:].billing_history
	[Return]	@{value}[0]

Get Policy Benefits Data
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data[:].benefits
	[Return]	@{value}[0]

Get Policy End Date
	[Arguments]    ${response}
	${value}=  Get Value From Json      ${response.json()}  $..dates[?(@.name="End Date")].date
	[Return]   @{value}[0]

Get Payment Card No by ID
	[Arguments]		${username}		${password}		${card_id}
	${response}=  	GET Payment Card Details   ${username}		${password}
	${json_path}= 	Replace String 	$.data[?(@.id==$id)].masked_number 	$id 	${card_id}
	${value}= 	Get Value From Json 	${response.json()} 	${json_path}
	[Return]	${value}[0]

Get Promo Code Message
	[Arguments]		${response}
	${value}= 	Get Value From Json 	${response.json()} 	$.data[:].message
	[Return]	${value}[0]

Check Policy Benefits
	[Arguments]		${response}		${amount}	
	${cancer}=			Set Variable 	plan_benefit_pet_cancercash10k	
	${benefits}=		Get Policy Benefits Data  ${response}
	${total_record}=	Get Length  ${benefits}	
	:FOR   ${index}   IN RANGE  ${total_record}
	\	${name}= 	Get Value From Json 	${response.json()} 	$.data.benefits[${index}].name
	\	${limit}= 	Get Value From Json 	${response.json()} 	$.data.benefits[${index}].limit
	\	${limit}= 	Convert to String 	${limit}[0]
	\	${limit_balance}= 	Get Value From Json 	${response.json()} 	$.data.benefits[${index}].limit_balance
	\	${limit_balance}= 	Convert to String 	${limit_balance}[0]
    \   ### Other Benefits ###
    \   Run Keyword If    '${name}[0]'!='${cancer}'   
        ...   Should Be Equal  ${limit}				${amount} 
        ...   Should Be Equal  ${limit_balance}		${amount} 
	\ 	### Camcer Benefits ###
    \   Run Keyword If    '${name}[0]'=='${cancer}'
        ...   Should Be Equal  ${limit}				10000.0 
        ...   Should Be Equal  ${limit_balance}		10000.0 
	\ 


############# VET PORTAL ##################
Init Vet Portal Login Session
	${dict_cookie}=  Create Dictionary   CSRF-TOKEN=${CSRF_token} 	path=/	domain=${URL_API_DOMAIN}
	RequestsLibrary.Create Session 	alias=${login_session} 	url=${URL_API_VET}  	verify=${False} 	timeout=60 	disable_warnings=0 	cookies=${dict_cookie}

Call API Login Vet Portal
	[Arguments]	${username}	${password}
	Init Vet Portal Login Session
    ${body}=	Create Dictionary   email=${username}	password=${password}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Post Request 	${login_session}	${URI_login}	headers=${headers} 	data=${body}
	${access_token}= 	JSONLibrary.Get Value From Json 	${response.headers} 	$..Set-Cookie
	${access_token}=	Convert To String	${access_token}
	${access_token}=	Fetch From Right	${access_token}	ACCESS_TOKEN=
	${access_token}=	Fetch From Left	${access_token}	; Expires
	${access_token}= 	Set Variable 	${access_token}
	[Return]	${access_token}

#here
GET Vet Certs ID From Vet
	[Arguments]	${access_token}  ${claim_name}
	Init Vet Portal Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_clinic_vet_certs}	headers=${headers} 
	Response Status Should Be 200 OK 	${response}	
	${vet_cert_list_name}= 	Get Value From Json 	${response.json()} 	$..data[:].claim_name

	${index}= 	Get Index From List		${vet_cert_list_name}	${claim_name}
	${vet_cert_list_id}= 	Get Value From Json 	${response.json()} 	$..data[:].id

	Log to console 	[ RESPONSE ] Vet Certs ID : @{vet_cert_list_id}[${index}]	

	[Return]	${vet_cert_list_id}[${index}]

Call API Update Vet Report
	[Arguments]	${access_token}  ${cert_id}		${dict_data}
	Init Vet Portal Request Session 	${access_token}
	${cert_id}= 	convert to string 	${cert_id}
	${URI_VET_cert}= 	Replace String 	${URI_VET_cert}  	$cert_id 	${cert_id}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}

	${response}= 	RequestsLibrary.Patch Request 	${request_session} 	${URI_VET_cert}	 data=${dict_data} 	headers=${headers} 	
	Response Status Should Be 200 OK 	${response}	

Call API Submit Vet Report
	[Arguments]	${access_token}  ${cert_id}
	Init Vet Portal Request Session 	${access_token}
	${cert_id}= 	convert to string 	${cert_id}
	${URI_VET_cert_submit}= 	Replace String 	${URI_VET_cert_submit}  	$cert_id 	${cert_id}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
  	
	${response}= 	RequestsLibrary.Post Request 	${request_session} 	${URI_VET_cert_submit}	headers=${headers} 	
	Log to console 	[ RESPONSE ]Call API Submit Vet Report : ${response.json()}
	Response Status Should Be 200 OK 	${response}


Call API Get The Vet Expenses
	[Arguments]		${access_token}		${vetexpense}
	Init Vet Portal Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	
	${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_VET_expenses}	headers=${headers} 
	Response Status Should Be 200 OK 	${response}	
	${vetexpense_list}= 	Get Value From Json 	${response.json()} 	$..data[:].name

	${namespace}=  Get Namespace 	${vetexpense}
 	${key_vetexpense}=  Get Key From Key-Text 	${vetexpense} 	${namespace}	
	
	${index}= 	Get Index From List		${vetexpense_list}	${key_vetexpense}
	${vetexpense_id_list}= 	Get Value From Json 	${response.json()} 	$..data[:].id

	Log to console 	[ RESPONSE ] Vet Certs ID : @{vetexpense_id_list}[${index}]

	[Return]	@{vetexpense_id_list}[${index}]

Call API Get The Vet Diagnoses
	[Arguments]		${access_token}		${vetdiagnoses}
	Init Vet Portal Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
	
	${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_VET_diagnoses}	headers=${headers} 
	Response Status Should Be 200 OK 	${response}	
	${vetdiagnoses_list}= 	Get Value From Json 	${response.json()} 	$..data[:].name

	${namespace}=  Get Namespace 	${vetdiagnoses}
 	${key_vetdiagnoses}=  Get Key From Key-Text 	${vetdiagnoses} 	${namespace}	
	
	${index}= 	Get Index From List		${vetdiagnoses_list}	${key_vetdiagnoses}
	${vetdiagnoses_id_list}= 	Get Value From Json 	${response.json()} 	$..data[:].id

	Log to console 	[ RESPONSE ] Vet Certs ID : @{vetdiagnoses_id_list}[${index}]

	[Return]	@{vetdiagnoses_id_list}[${index}]


Init Vet Portal Request Session
	[Arguments]	${token}
    ${dict_cookie}=  Create Dictionary   ACCESS_TOKEN=${token} 	CSRF-TOKEN=${CSRF_token} 	path=/	domain=${URL_API_DOMAIN}
	RequestsLibrary.Create Session 	alias=${request_session} 	url=${URL_API_VET} 	cookies=${dict_cookie}		verify=${False} 	timeout=60     

Call API Get Clinic Profile 
	[Arguments]	${access_token}
	Init Vet Portal Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_clinic_profile_get}	headers=${headers} 	
	Log to console 	[ RESPONSE ]GET User Profile Response : ${response.json()}
	Response Status Should Be 200 OK 	${response}
	[Return]	${response}

GET Clinic Profile
	[Arguments]	${username}	 ${password}
    ${access_token}=    Call API Login Vet Portal 	${username}   ${password}
	${response}= 	Call API Get Clinic Profile     ${access_token}
	[Return]	${response}

GET Vet Certs Info
	[Arguments]	${username}	 ${password}
    ${access_token}=    Call API Login Vet Portal 	${username}   ${password}
	Init Vet Portal Request Session 	${access_token}
	${headers}= 	Create Dictionary 	Accept=application/json   Content-Type=application/json		CSRF-TOKEN=${CSRF_token}	Origin=${URL_API_DOMAIN}
    ${response}= 	RequestsLibrary.Get Request 	${request_session} 	${URI_clinic_vet_certs}	headers=${headers} 
	Response Status Should Be 200 OK 	${response}	
	${clinic_id}= 	Get Value From Json 	${response.json()} 	$..data[?(@.clinic_id!=null)].clinic_id
	Log to console 	[ RESPONSE ]Clinic Id : @{clinic_id}[0]
	${vet_id}= 	Get Value From Json 	${response.json()} 	$..data[?(@.vet_id!=null)].vet_id
	Log to console 	[ RESPONSE ]Vet Id : @{vet_id}[0]
	[Return]	${clinic_id}[0]	${vet_id}[0]

GET Clinic Address
	[Arguments]	 ${response}   ${namespace} 
	${street}=   Get Value From Json 	${response.json()} 	$.data.street
	${street2}=  Get Value From Json 	${response.json()} 	$.data.street2
	${city}=   	 Get Value From Json    ${response.json()}  $.data.city


	${street}=  Change Key To Value In Specific Langauge   ${street}[0]   ${namespace}   ${en}
	${street2}=  Change Key To Value In Specific Langauge  ${street2}[0]  ${namespace}   ${en}
	${city}=  Change Key To Value In Specific Langauge     ${city}[0]  	  ${namespace}   ${en}

	${address}=  Set Variable  ${street} ${street2} ${city}

	[Return]	${address}

############# Data Preparation ##################
Prepare promotion code
	Create promo code if not exist 		OFF10UNLIMIT
	Create promo code if not exist 		OFF10FULL
	Create promo code if not exist 		FREE2UNLIMIT
	Create promo code if not exist 		FREE2EXPIRED

Create promo code if not exist
	[Arguments]  ${promo_code}	
	${response}=  	GET Promotion Details by Promo Code   ${effective_username}   ${effective_password}  ${promo_code}
	${status}=		Get Promo Code Message  ${response}	
	Run Keyword If 	'${promo_code}'=='OFF10UNLIMIT' and '${status}'!='valid'	
	...   Call API create promo code	${promo_code}
	...   ELSE IF 	'${promo_code}'=='OFF10UNLIMIT' and '${status}'=='valid'
	...   Log to console 		>>>The ${promo_code} promotion code already exists 

	Run Keyword If 	'${promo_code}'=='OFF10FULL' and '${status}'!='exceed limit'	
	...   Call API create promo code	${promo_code}
	...   ELSE IF 	'${promo_code}'=='OFF10FULL' and '${status}'=='exceed limit' 
	...   Log to console 		>>>The ${promo_code} promotion code already exists 

	Run Keyword If 	'${promo_code}'=='FREE2UNLIMIT' and '${status}'!='valid'	
	...   Call API create promo code	${promo_code}
	...   ELSE IF 	'${promo_code}'=='FREE2UNLIMIT' and '${status}'=='valid'	 
	...   Log to console 		>>>The ${promo_code} promotion code already exists 

	Run Keyword If 	'${promo_code}'=='FREE2EXPIRED' and '${status}'!='expired'	
	...   Call API create promo code	${promo_code}
	...   ELSE IF	'${promo_code}'=='FREE2EXPIRED' and '${status}'=='expired'
	...   Log to console 		>>>The ${promo_code} promotion code already exists

BYPASS API Buying a New Policy
    [Arguments]  ${plan}=&{bypass_plan}[Ultra]	${payment}=monthly	 ${pet_name}=${bypass_petname}  ${owner_firstname}=${bypass_firstname}  ${owner_lastname}=${bypass_lastname}  ${promo}=${EMPTY}
    
    ${email-address}=  Generate email address
    ${HKID}=  Generate HKID
    ${avid}=  Get AVID String
    
    ${plan}=        Change Key-Text From Key To Value  ${plan}
    ${ultra}=     Change Key-Text From Key To Value  &{purchase}[plan_pet_ul9070]
    ${essential}=   Change Key-Text From Key To Value  &{purchase}[plan_pet_es9025]
    ${plus}=        Change Key-Text From Key To Value  &{purchase}[plan_pet_pr9030]

    ${plan}=        convert to lowercase  ${plan}
    ${ultra}=     convert to lowercase  ${ultra}
    ${essential}=   convert to lowercase  ${essential}
    ${plus}=        convert to lowercase  ${plus}

    ${set_plan_id}=  run keyword if  '${plan}'=='${ultra}'  
    ...     Set Variable    4
    ...     ELSE IF  '${plan}'=='${essential}'   
    ...     Set Variable    2
    ...     ELSE IF  '${plan}'=='${plus}'  
    ...     Set Variable    3

	${pet_breed_id}= 	Convert To Integer 	4
    ${pet_type_id}= 	Convert To Integer 	2
	${plan_id}= 	    Convert To Integer 	${set_plan_id}

    &{policy_body_json}  Create Dictionary    
    Set To Dictionary  ${policy_body_json}  address          ${bypass_address1}
    Set To Dictionary  ${policy_body_json}  area             central_and_western
    Set To Dictionary  ${policy_body_json}  birth_date       2000-11-11
    Set To Dictionary  ${policy_body_json}  email            ${email-address}
    Set To Dictionary  ${policy_body_json}  firstname        ${owner_firstname}
    Set To Dictionary  ${policy_body_json}  hkid             ${HKID}
    Set To Dictionary  ${policy_body_json}  lastname         ${owner_lastname}
    Set To Dictionary  ${policy_body_json}  mobile           ${bypass_mobileNo}
    Set To Dictionary  ${policy_body_json}  payment_mode     ${payment}
    Set To Dictionary  ${policy_body_json}  pet_age_range    13w11m
    Set To Dictionary  ${policy_body_json}  pet_breed_id     ${pet_breed_id}
    Set To Dictionary  ${policy_body_json}  pet_gender       male
    Set To Dictionary  ${policy_body_json}  pet_microchip    ${avid}
    Set To Dictionary  ${policy_body_json}  pet_name         ${pet_name}
    Set To Dictionary  ${policy_body_json}  pet_type_id      ${pet_type_id}
    Set To Dictionary  ${policy_body_json}  plan_id          ${plan_id}    
    ${promotion_allow} =    Create List     email
    Set To Dictionary  ${policy_body_json}  promotion_allow  ${promotion_allow}
	${promo_codes} =    Create List     ${promo}
    Run Keyword If  '${promo}'!='${EMPTY}'
    ...     Set To Dictionary  ${policy_body_json}  promo_codes  ${promo_codes}

    ${policy_id}=  Call API Create a Policy  ${policy_body_json}

    Call API Underwrite     ${policy_id}
    ${payment_card_id}=  Call API Create Payment Card  
    Call API Pay For Policy     ${policy_id}    ${payment_card_id}
    Call API Update Policy Password     -   ${bypass_pwd}
    Call API Send Account Verification Email
     
	[Return]	${email-address}

BYPASS API Buying a New Policy for Save Quote
    [Arguments]  ${plan}=&{bypass_plan}[Ultra]	${payment}=monthly	 ${pet_name}=${bypass_petname}  ${owner_firstname}=${bypass_firstname}  ${owner_lastname}=${bypass_lastname}  ${promo}=${EMPTY}
    
    ${email-address}=  Generate email address
    ${HKID}=  Generate HKID
    ${avid}=  Get AVID String
    
    ${plan}=        Change Key-Text From Key To Value  ${plan}
    ${ultra}=     Change Key-Text From Key To Value  &{purchase}[plan_pet_ul9070]
    ${essential}=   Change Key-Text From Key To Value  &{purchase}[plan_pet_es9025]
    ${plus}=        Change Key-Text From Key To Value  &{purchase}[plan_pet_pr9030]

    ${plan}=        convert to lowercase  ${plan}
    ${ultra}=     convert to lowercase  ${ultra}
    ${essential}=   convert to lowercase  ${essential}
    ${plus}=        convert to lowercase  ${plus}

    ${set_plan_id}=  run keyword if  '${plan}'=='${ultra}'  
    ...     Set Variable    4
    ...     ELSE IF  '${plan}'=='${essential}'   
    ...     Set Variable    2
    ...     ELSE IF  '${plan}'=='${plus}'  
    ...     Set Variable    3

	${pet_breed_id}= 	Convert To Integer 	4
    ${pet_type_id}= 	Convert To Integer 	2
	${plan_id}= 	    Convert To Integer 	${set_plan_id}

    &{policy_body_json}  Create Dictionary    
    Set To Dictionary  ${policy_body_json}  address          ${bypass_address1}
    Set To Dictionary  ${policy_body_json}  area             central_and_western
    Set To Dictionary  ${policy_body_json}  birth_date       2000-11-11
    Set To Dictionary  ${policy_body_json}  email            ${email-address}
    Set To Dictionary  ${policy_body_json}  firstname        ${owner_firstname}
    Set To Dictionary  ${policy_body_json}  hkid             ${HKID}
    Set To Dictionary  ${policy_body_json}  lastname         ${owner_lastname}
    Set To Dictionary  ${policy_body_json}  mobile           ${bypass_mobileNo}
    Set To Dictionary  ${policy_body_json}  payment_mode     ${payment}
    Set To Dictionary  ${policy_body_json}  pet_age_range    13w11m
    Set To Dictionary  ${policy_body_json}  pet_breed_id     ${pet_breed_id}
    Set To Dictionary  ${policy_body_json}  pet_gender       male
    Set To Dictionary  ${policy_body_json}  pet_microchip    ${avid}
    Set To Dictionary  ${policy_body_json}  pet_name         ${pet_name}
    Set To Dictionary  ${policy_body_json}  pet_type_id      ${pet_type_id}
    Set To Dictionary  ${policy_body_json}  plan_id          ${plan_id}    
    ${promotion_allow} =    Create List     email
    Set To Dictionary  ${policy_body_json}  promotion_allow  ${promotion_allow}
	${promo_codes} =    Create List     ${promo}
    Run Keyword If  '${promo}'!='${EMPTY}'
    ...     Set To Dictionary  ${policy_body_json}  promo_codes  ${promo_codes}

    ${policy_id}=  Call API Create a Policy  ${policy_body_json}
	Log to console	Email is: ${email-address}
	[Return]	${policy_id}	${email-address}

BYPASS API Buying an Additionaly Policy
	[Arguments]   ${login_username}  ${login_password}  ${plan}=&{bypass_plan}[Ultra]	 ${payment}=monthly	 ${pet_name}=${bypass_petname}  ${owner_firstname}=${bypass_firstname}  ${owner_lastname}=${bypass_lastname}  ${promo}=${EMPTY}

    ${avid}=  Get AVID String
    
    ${plan}=        Change Key-Text From Key To Value  ${plan}
    ${ultra}=     Change Key-Text From Key To Value  &{purchase}[plan_pet_ul9070]
    ${essential}=   Change Key-Text From Key To Value  &{purchase}[plan_pet_es9025]
    ${plus}=        Change Key-Text From Key To Value  &{purchase}[plan_pet_pr9030]

    ${plan}=        convert to lowercase  ${plan}
    ${ultra}=     convert to lowercase  ${ultra}
    ${essential}=   convert to lowercase  ${essential}
    ${plus}=        convert to lowercase  ${plus}

    ${set_plan_id}=  run keyword if  '${plan}'=='${ultra}'  
    ...     Set Variable    1
    ...     ELSE IF  '${plan}'=='${essential}'   
    ...     Set Variable    2
    ...     ELSE IF  '${plan}'=='${plus}'  
    ...     Set Variable    3

	${pet_breed_id}= 	Convert To Integer 	4
    ${pet_type_id}= 	Convert To Integer 	2
	${plan_id}= 	    Convert To Integer 	${set_plan_id}

    &{policy_body_json}  Create Dictionary    
    Set To Dictionary  ${policy_body_json}  payment_mode     ${payment}
    Set To Dictionary  ${policy_body_json}  pet_age_range    13w11m
    Set To Dictionary  ${policy_body_json}  pet_breed_id     ${pet_breed_id}
    Set To Dictionary  ${policy_body_json}  pet_gender       male
    Set To Dictionary  ${policy_body_json}  pet_microchip    ${avid}
    Set To Dictionary  ${policy_body_json}  pet_name         ${pet_name}
    Set To Dictionary  ${policy_body_json}  pet_type_id      ${pet_type_id}
    Set To Dictionary  ${policy_body_json}  plan_id          ${plan_id}    
	${promo_codes} =    Create List     ${promo}
    Run Keyword If  '${promo}'!='${EMPTY}'
    ...     Set To Dictionary  ${policy_body_json}  promo_codes  ${promo_codes}

	${policy_id}=  Call API Create Second Policy  ${login_username}  ${login_password}  ${policy_body_json}
	Call API Underwrite     ${policy_id}
    ${payment_card_id}=  Call API Create Payment Card  
    Call API Pay For Policy     ${policy_id}    ${payment_card_id}
    
	[return]  ${policy_id}

Verify Email via API
    [Arguments]		${email-address}
    Wait For Email Sent 
	## Finish setting up your OneDegree account
	${email_subject}=  Change Key-Text From Key To Value   &{email}[email_verification_title]
	## Verify My Email
	${btn_verify_my_email}=  Change Key-Text From Key To Value  &{email}[email_verification_button]
	${url}=    Get Link From Button  ${email-address}    ${email_subject}  ${btn_verify_my_email}
    ${pattern_link}=   Set Variable         token=(\\w+)                                                   
    ${match_link}=     Get Regexp Matches   ${url}  ${pattern_link}
    ${token}=          Set Variable         ${match_link[0]}
    ${token}=          Remove String        ${token}  token=
            
    ${access_token}=    Call API Login  ${email-address}   ${bypass_pwd}
    Call API Verify Email   ${access_token}     ${token}


*** Settings ***
Documentation    Test to retrieve all product prices across all pagination pages.

Library    RequestsLibrary
Library    JSONLibrary
Library    Collections    # Needed for Create List, Append To List, Get Length, List Should Be Empty
Library    BuiltIn    # Needed for Log To Console, Evaluate, Should Be Equal As Integers, Should Not Be Empty

*** Variables ***
${API_BASE_URL}         https://api.practicesoftwaretesting.com

*** Test Cases ***

GET All Product Prices Across All Pages
    [Documentation]    Retrieves product prices from all pagination pages and verifies total count.

    Create Session    mysession    ${API_BASE_URL}

    # Step 1 & 2: Get the first page and extract pagination info
    Log To Console    Getting first page of products...
    ${response_page1}=    GET On Session    mysession    /products
    Should Be Equal As Integers    ${response_page1.status_code}    200    msg=Failed to get first page. Status: ${response_page1.status_code}, Response: ${response_page1.text}
    ${response_json_page1}=    Convert String To Json    ${response_page1.text}

    Dictionary Should Contain Key    ${response_json_page1}    total
    Dictionary Should Contain Key    ${response_json_page1}    last_page
    Dictionary Should Contain Key    ${response_json_page1}    data

    ${total_items}=    Get Value From Json    ${response_json_page1}    total
    ${last_page_number}=    Get Value From Json    ${response_json_page1}    last_page

    Log To Console    Total items: ${total_items}, Total pages: ${last_page_number}

    # Step 3: Initialize a list to store all prices
    ${all_product_prices}=    Create List

    # Step 4: Process the first page's data
    ${data_page1}=    Get Value From Json    ${response_json_page1}    data
    # Check if first page data is not empty before trying to extract prices
    Run Keyword If    ${data_page1} is not None and ${data_page1} != []
    ...    Run Keywords
    ...        ${prices_page1}=        Get Value From Json        ${response_json_page1}        $.data.*.price
    ...        Append To List    ${all_product_prices}    @{prices_page1}
    ...        Log To Console    Appended ${len(${prices_page1})} prices from page 1.
    ...    ELSE
    ...    Log To Console    Warning: First page data is empty.

    # Step 5: Iterate through subsequent pages (from page 2 up to last_page)
    # We need to loop from 2 up to last_page. IN RANGE is exclusive of the end number.
    ${last_page_plus_one}=    Evaluate    ${last_page_number} + 1
    FOR    ${page_num}    IN RANGE    2    ${last_page_plus_one}
        Log To Console    Getting page ${page_num}...
        ${params_current_page}=    Create Dictionary    page=${page_num}
        ${response_current_page}=    GET On Session    mysession    /products    params=${params_current_page}
        Should Be Equal As Integers    ${response_current_page.status_code}    200    msg=Failed to get page ${page_num}. Status: ${response_current_page.status_code}, Response: ${response_current_page.text}
        ${response_json_current_page}=    Convert String To Json    ${response_current_page.text}

        Dictionary Should Contain Key    ${response_json_current_page}    data
        ${data_current_page}=    Get Value From Json    ${response_json_current_page}    data

        # Process current page's data
        Run Keyword If    ${data_current_page} is not None and ${data_current_page} != []
        ...    Run Keywords
        ...        ${prices_current_page}=    Get Values From Json    ${response_json_current_page}    $.data.*.price
        ...        Append To List    ${all_product_prices}    @{prices_current_page}
        ...        Log To Console    Appended ${len(${prices_current_page})} prices from page ${page_num}.
        ...    ELSE
        ...    Log To Console    Page ${page_num} data is empty.

    END

    # Step 6: Verify the total number of prices collected
    ${total_prices_collected}=    Get Length    ${all_product_prices}
    Log To Console    Total prices collected across all pages: ${total_prices_collected}

    # Comparing collected count to the total count reported by the API
    Should Be Equal As Integers    ${total_prices_collected}    ${total_items}    msg=Number of prices collected (${total_prices_collected}) does not match total items reported by API (${total_items}).

    # Step 7 (Optional): Log or process the full list of 29 prices
    # Log To Console    All 29 prices: ${all_product_prices}

    # Optional: Verify all collected prices are numeric (or convert them)
    # FOR    ${price}    IN    @{all_product_prices}
    #     ${numeric_price}=    Convert To Number    ${price}
    #     # You could then perform other checks on ${numeric_price}
    # END


*** Keywords ***
# If you have Response Status Should Be 200 OK defined elsewhere, you don't need it here.
# Assuming you used 'Should Be Equal As Integers 200 ${response.status_code}' directly in the tests.
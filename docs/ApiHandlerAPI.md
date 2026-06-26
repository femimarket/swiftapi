# ApiHandlerAPI

All URIs are relative to *https://femi.market*

Method | HTTP request | Description
------------- | ------------- | -------------
[**apiHandler**](ApiHandlerAPI.md#apihandler) | **POST** /api | 


# **apiHandler**
```swift
    open class func apiHandler(API: API, completion: @escaping (_ data: API?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let API = API(action: ApiAction(description: "description_example", type: "type_example", falRequestId: "falRequestId_example", file: "file_example", prompt: "prompt_example", audio: "audio_example", comfyRequestId: "comfyRequestId_example", image: "image_example", image2: "image2_example", messages: [ApiChatMessage(content: "content_example", role: ApiChatRole())], credit: 123, currency: "currency_example", jws: "jws_example", loaded: false, price: 123, productId: "productId_example", transactionId: "transactionId_example", orderId: "orderId_example", packageName: "packageName_example", purchaseToken: "purchaseToken_example", lyrics: "lyrics_example"), credit: 123, id: 123, status: ApiStatus(), userId: "userId_example") // API | 

ApiHandlerAPI.apiHandler(API: API) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **API** | [**API**](API.md) |  | 

### Return type

[**API**](API.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)


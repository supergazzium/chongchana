class ErrorMessages {
  String id;
  dynamic message;
  ErrorMessages({
    this.id = "",
    this.message = "",
  });
}

class ServiceResponse<T> {
  late int statusCode;
  late bool isSuccess;
  dynamic data = null;
  List<ErrorMessages> errorMessages = [];

  dynamic get errorMessage => errorMessages.isNotEmpty ? errorMessages[0].message : "Error something wrong";

  ServiceResponse({
    this.isSuccess = false,
    this.statusCode = 400,
    this.data,
    this.errorMessages = const [],
  });

  success(Map<String, dynamic> json) {
    isSuccess = true;
    statusCode = 200;
    data = json["data"];
  }

  error(Map<String, dynamic> json) {
    isSuccess = false;
    statusCode = json["statusCode"];
    errorMessages = json["data"];
  }

  setErrorObject(Map<String, dynamic> json) {
    isSuccess = false;
    statusCode = json["statusCode"] ?? 500;

    // Handle nested error structure from Strapi
    if (json["data"] != null && json["data"] is List && json["data"].isNotEmpty) {
      var dataList = json["data"] as List;
      if (dataList[0] is Map && dataList[0]["messages"] != null) {
        var messages = dataList[0]["messages"] as List;
        if (messages.isNotEmpty) {
          var firstMessage = messages[0] as Map<String, dynamic>;
          ErrorMessages e = ErrorMessages(
            id: firstMessage["id"] ?? "",
            message: firstMessage["message"] ?? "Unknown error"
          );
          errorMessages = [e];
          return;
        }
      }
    }

    // Fallback to simple message structure
    var message = json["message"];
    if (message is String) {
      ErrorMessages e = ErrorMessages(id: "", message: message);
      errorMessages = [e];
    } else {
      ErrorMessages e = ErrorMessages(id: "", message: "Unknown error occurred");
      errorMessages = [e];
    }
  }
}

// lib/services/customer_apiservice.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../masters/customermaster.dart';
import 'config.dart';

class CustomerApiService {

  Future<String> insertCustomer({
    required BuildContext context,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String refercontact,
    required String spousename,
    required String spousecontact,
    String? aadharFile,
    String? photoFile,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/customer_insert.php');

    if (kIsWeb) {
      // Web version - use simple POST with base64
      return _insertCustomerWeb(
        context: context,
        url: url,
        companyid: companyid,
        userid: userid,
        customername: customername,
        mobile1: mobile1,
        mobile2: mobile2,
        address: address,
        area: area,
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        refercontact: refercontact,
        spousename: spousename,
        spousecontact: spousecontact,
        aadharFile: aadharFile,
        photoFile: photoFile,
      );
    } else {
      // Mobile/Desktop version - use multipart
      return _insertCustomerMobile(
        context: context,
        url: url,
        companyid: companyid,
        userid: userid,
        customername: customername,
        mobile1: mobile1,
        mobile2: mobile2,
        address: address,
        area: area,
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        refercontact: refercontact,
        spousename: spousename,
        spousecontact: spousecontact,
        aadharFile: aadharFile,
        photoFile: photoFile,
      );
    }
  }

  Future<String> _insertCustomerMobile({
    required BuildContext context,
    required Uri url,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String refercontact,
    required String spousename,
    required String spousecontact,
    String? aadharFile,
    String? photoFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', url);

      // Add text fields
      request.fields['companyid'] = companyid;
      request.fields['customername'] = customername;
      request.fields['gst_no'] = gstNo;
      request.fields['address'] = address;
      request.fields['area'] = area;
      request.fields['areaid'] = areaid;
      request.fields['mobile1'] = mobile1;
      request.fields['mobile2'] = mobile2;
      request.fields['refer'] = refer;
      request.fields['refercontact'] = refercontact;
      request.fields['spousename'] = spousename;
      request.fields['spousecontact'] = spousecontact;
      request.fields['addedby'] = userid;
      request.fields['activestatus'] = '1';

      // Add Aadhar file if exists
      if (aadharFile != null && aadharFile.isNotEmpty) {
        var file = File(aadharFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'aadharfile',
            aadharFile,
            filename: 'aadhar_${DateTime.now().millisecondsSinceEpoch}',
          ));
        }
      }

      // Add Photo file if exists
      if (photoFile != null && photoFile.isNotEmpty) {
        var file = File(photoFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'photofile',
            photoFile,
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}',
          ));
        }
      }

      print("Sending mobile request to: $url");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("Mobile Response Status: ${response.statusCode}");
      print("Mobile Response Body: $responseBody");

      return _handleResponse(context, responseBody);

    } catch (e) {
      print("Mobile Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  Future<String> _insertCustomerWeb({
    required BuildContext context,
    required Uri url,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String refercontact,
    required String spousename,
    required String spousecontact,
    String? aadharFile,
    String? photoFile,
  }) async {
    try {
      // For web, we send as regular POST
      var data = {
        'companyid': companyid,
        'customername': customername,
        'gst_no': gstNo,
        'address': address,
        'area': area,
        'areaid': areaid,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'refer': refer,
        'refercontact': refercontact,
        'spousename': spousename,
        'spousecontact': spousecontact,
        'addedby': userid,
        'activestatus': '1',
        'platform': 'web',
      };

      // Add base64 files if they exist
      if (aadharFile != null && aadharFile.isNotEmpty) {
        data['aadhar_base64'] = aadharFile;
      }
      if (photoFile != null && photoFile.isNotEmpty) {
        data['photo_base64'] = photoFile;
      }

      print("Sending web request to: $url");

      var response = await http.post(
        url,
        body: data,
      );

      print("Web Response Status: ${response.statusCode}");
      print("Web Response Body: ${response.body}");

      return _handleResponse(context, response.body);

    } catch (e) {
      print("Web Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  Future<String> updateCustomer({
    required BuildContext context,
    required String customerId,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String refercontact,
    required String spousename,
    required String spousecontact,
    String? aadharFile,
    String? photoFile,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/customer_update.php');

    if (kIsWeb) {
      return _updateCustomerWeb(
        context: context,
        url: url,
        customerId: customerId,
        companyid: companyid,
        userid: userid,
        customername: customername,
        mobile1: mobile1,
        mobile2: mobile2,
        address: address,
        area: area,
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        refercontact: refercontact,
        spousename: spousename,
        spousecontact: spousecontact,
        aadharFile: aadharFile,
        photoFile: photoFile,
      );
    } else {
      return _updateCustomerMobile(
        context: context,
        url: url,
        customerId: customerId,
        companyid: companyid,
        userid: userid,
        customername: customername,
        mobile1: mobile1,
        mobile2: mobile2,
        address: address,
        area: area,
        areaid: areaid,
        gstNo: gstNo,
        refer: refer,
        refercontact: refercontact,
        spousename: spousename,
        spousecontact: spousecontact,
        aadharFile: aadharFile,
        photoFile: photoFile,
      );
    }
  }

  Future<String> _updateCustomerMobile({
    required BuildContext context,
    required Uri url,
    required String customerId,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String refercontact,
    required String spousename,
    required String spousecontact,
    String? aadharFile,
    String? photoFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', url);

      request.fields['customerid'] = customerId;
      request.fields['companyid'] = companyid;
      request.fields['customername'] = customername;
      request.fields['gst_no'] = gstNo;
      request.fields['address'] = address;
      request.fields['area'] = area;
      request.fields['areaid'] = areaid;
      request.fields['mobile1'] = mobile1;
      request.fields['mobile2'] = mobile2;
      request.fields['refer'] = refer;
      request.fields['refercontact'] = refercontact;
      request.fields['spousename'] = spousename;
      request.fields['spousecontact'] = spousecontact;
      request.fields['addedby'] = userid;

      if (aadharFile != null && aadharFile.isNotEmpty) {
        var file = File(aadharFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'aadharfile',
            aadharFile,
            filename: 'aadhar_${DateTime.now().millisecondsSinceEpoch}',
          ));
        }
      }

      if (photoFile != null && photoFile.isNotEmpty) {
        var file = File(photoFile);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'photofile',
            photoFile,
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}',
          ));
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      return _handleResponse(context, responseBody);

    } catch (e) {
      print("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  Future<String> _updateCustomerWeb({
    required BuildContext context,
    required Uri url,
    required String customerId,
    required String companyid,
    required String userid,
    required String customername,
    required String mobile1,
    required String mobile2,
    required String address,
    required String area,
    required String areaid,
    required String gstNo,
    required String refer,
    required String refercontact,
    required String spousename,
    required String spousecontact,
    String? aadharFile,
    String? photoFile,
  }) async {
    try {
      var data = {
        'customerid': customerId,
        'companyid': companyid,
        'customername': customername,
        'gst_no': gstNo,
        'address': address,
        'area': area,
        'areaid': areaid,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'refer': refer,
        'refercontact': refercontact,
        'spousename': spousename,
        'spousecontact': spousecontact,
        'addedby': userid,
        'platform': 'web',
      };

      if (aadharFile != null && aadharFile.isNotEmpty) {
        data['aadhar_base64'] = aadharFile;
      }
      if (photoFile != null && photoFile.isNotEmpty) {
        data['photo_base64'] = photoFile;
      }

      var response = await http.post(
        url,
        body: data,
      );

      return _handleResponse(context, response.body);

    } catch (e) {
      print("Update Web Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  String _handleResponse(BuildContext context, String responseBody) {
    try {
      var message = jsonDecode(responseBody);

      if (message["status"] == "success") {
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message["message"] ?? "Unknown error"),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    } catch (e) {
      print("Response Parse Error: $e");
      print("Raw Response: $responseBody");

      // Try to extract error message
      if (responseBody.toLowerCase().contains("success")) {
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server response: ${responseBody.substring(0, 100)}"),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    }
  }

  Future<List<CustomerMasterModel>> fetchCustomers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/customer_fetch.php');
    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> items = json.decode(response.body);
        List<CustomerMasterModel> customers = items.map((item) =>
            CustomerMasterModel.fromJson(item)).toList();
        return customers;
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      rethrow;
    }
  }

  Future<String> deleteCustomer(BuildContext context, String customerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/customer_delete.php');
    try {
      var response = await http.post(
        url,
        body: {
          'customerid': customerId,
          'companyid': companyid,
        },
      );

      var message = jsonDecode(response.body);
      print("Delete Response: $message");

      if (response.statusCode == 200) {
        if (message["status"] == "success") {
          return "Success";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message["message"]),
              backgroundColor: Colors.red,
            ),
          );
          return "Failed";
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("Delete Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }
}
// // lib/services/customer_apiservice.dart
// import 'dart:convert';
// import 'dart:html' as html; // For web
// import 'dart:io'; // For mobile/desktop
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'config.dart';
//
// class CustomerApiService {
//
//   // Convert file to base64 for web or get path for mobile
//   Future<Map<String, dynamic>> _prepareFileData(String? filePath, String fieldName) async {
//     if (filePath == null || filePath.isEmpty) return {};
//
//     if (kIsWeb) {
//       // Web version - convert to base64
//       try {
//         // For web, we need to handle file picking differently
//         // This assumes filePath is actually a base64 string for web
//         if (filePath.contains('data:')) {
//           // Already base64
//           return {fieldName: filePath};
//         }
//       } catch (e) {
//         print("Error preparing web file: $e");
//       }
//       return {};
//     } else {
//       // Mobile/Desktop version - use file path
//       return {fieldName: filePath};
//     }
//   }
//
//   Future<String> insertCustomer({
//     required BuildContext context,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String refercontact,
//     required String spousename,
//     required String spousecontact,
//     String? aadharFile,
//     String? photoFile,
//   }) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final companyid = prefs.getString('companyid') ?? '';
//     final userid = prefs.getString('id') ?? '';
//
//     var url = Uri.parse('$baseUrl/customer_insert.php');
//
//     if (kIsWeb) {
//       // Web version - use FormData with base64
//       return _insertCustomerWeb(
//         context: context,
//         url: url,
//         companyid: companyid,
//         userid: userid,
//         customername: customername,
//         mobile1: mobile1,
//         mobile2: mobile2,
//         address: address,
//         area: area,
//         areaid: areaid,
//         gstNo: gstNo,
//         refer: refer,
//         refercontact: refercontact,
//         spousename: spousename,
//         spousecontact: spousecontact,
//         aadharFile: aadharFile,
//         photoFile: photoFile,
//       );
//     } else {
//       // Mobile/Desktop version - use multipart
//       return _insertCustomerMobile(
//         context: context,
//         url: url,
//         companyid: companyid,
//         userid: userid,
//         customername: customername,
//         mobile1: mobile1,
//         mobile2: mobile2,
//         address: address,
//         area: area,
//         areaid: areaid,
//         gstNo: gstNo,
//         refer: refer,
//         refercontact: refercontact,
//         spousename: spousename,
//         spousecontact: spousecontact,
//         aadharFile: aadharFile,
//         photoFile: photoFile,
//       );
//     }
//   }
//
//   // Mobile/Desktop implementation
//   Future<String> _insertCustomerMobile({
//     required BuildContext context,
//     required Uri url,
//     required String companyid,
//     required String userid,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String refercontact,
//     required String spousename,
//     required String spousecontact,
//     String? aadharFile,
//     String? photoFile,
//   }) async {
//     try {
//       var request = http.MultipartRequest('POST', url);
//
//       // Add text fields
//       request.fields['companyid'] = companyid;
//       request.fields['customername'] = customername;
//       request.fields['gst_no'] = gstNo;
//       request.fields['address'] = address;
//       request.fields['area'] = area;
//       request.fields['areaid'] = areaid;
//       request.fields['mobile1'] = mobile1;
//       request.fields['mobile2'] = mobile2;
//       request.fields['refer'] = refer;
//       request.fields['refercontact'] = refercontact;
//       request.fields['spousename'] = spousename;
//       request.fields['spousecontact'] = spousecontact;
//       request.fields['addedby'] = userid;
//       request.fields['activestatus'] = '1';
//
//       // Add Aadhar file if exists
//       if (aadharFile != null && aadharFile.isNotEmpty) {
//         var file = File(aadharFile);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath(
//             'aadharfile',
//             aadharFile,
//           ));
//         }
//       }
//
//       // Add Photo file if exists
//       if (photoFile != null && photoFile.isNotEmpty) {
//         var file = File(photoFile);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath(
//             'photofile',
//             photoFile,
//           ));
//         }
//       }
//
//       print("Sending mobile request to: $url");
//
//       var response = await request.send();
//       var responseBody = await response.stream.bytesToString();
//
//       print("Mobile Response: $responseBody");
//
//       return _handleResponse(context, responseBody);
//
//     } catch (e) {
//       print("Mobile Error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return "Failed";
//     }
//   }
//
//   // Web implementation using simple POST
//   Future<String> _insertCustomerWeb({
//     required BuildContext context,
//     required Uri url,
//     required String companyid,
//     required String userid,
//     required String customername,
//     required String mobile1,
//     required String mobile2,
//     required String address,
//     required String area,
//     required String areaid,
//     required String gstNo,
//     required String refer,
//     required String refercontact,
//     required String spousename,
//     required String spousecontact,
//     String? aadharFile,
//     String? photoFile,
//   }) async {
//     try {
//       // For web, we send as regular POST without files
//       // Or you can implement base64 file upload
//
//       var data = {
//         'companyid': companyid,
//         'customername': customername,
//         'gst_no': gstNo,
//         'address': address,
//         'area': area,
//         'areaid': areaid,
//         'mobile1': mobile1,
//         'mobile2': mobile2,
//         'refer': refer,
//         'refercontact': refercontact,
//         'spousename': spousename,
//         'spousecontact': spousecontact,
//         'addedby': userid,
//         'activestatus': '1',
//         'platform': 'web',
//       };
//
//       // If you want to send base64 files
//       if (aadharFile != null && aadharFile.isNotEmpty) {
//         data['aadhar_base64'] = aadharFile;
//       }
//       if (photoFile != null && photoFile.isNotEmpty) {
//         data['photo_base64'] = photoFile;
//       }
//
//       print("Sending web request to: $url");
//       print("Data: $data");
//
//       var response = await http.post(
//         url,
//         body: data,
//       );
//
//       print("Web Response: ${response.body}");
//
//       return _handleResponse(context, response.body);
//
//     } catch (e) {
//       print("Web Error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return "Failed";
//     }
//   }
//
//   String _handleResponse(BuildContext context, String responseBody) {
//     try {
//       var message = jsonDecode(responseBody);
//
//       if (message["status"] == "success") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message["message"]),
//             backgroundColor: Colors.green,
//           ),
//         );
//         return "Success";
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message["message"] ?? "Unknown error"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return "Failed";
//       }
//     } catch (e) {
//       print("Response Parse Error: $e");
//       print("Raw Response: $responseBody");
//
//       // Try to extract error message from non-JSON response
//       if (responseBody.contains("success")) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Success"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         return "Success";
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Server error: $responseBody"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return "Failed";
//       }
//     }
//   }
// }
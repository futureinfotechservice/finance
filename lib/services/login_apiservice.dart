// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/modules.dart';

import '../screens/home.dart';
import 'auth_service.dart';
import 'config.dart';



class ApiService {

  List<login_data> loginlist = [];





  Future login(BuildContext context,String username, String password, String mailid, String unique_id, String platform ) async {
    final url = Uri.parse('$baseUrl/login.php');

    final response = await http.post(
      url,
      body: json.encode({
        'username': username,
        'password': password,
        'email': mailid,
        'platform': platform.toString(),
        'unique_id': unique_id.toString(),
      }),
    );

    var message = response.body.toString();
    print(message.toString());
    if (message.toString().contains('login success')) {
      ApiService().userdata(context,username,password,mailid,unique_id,platform);

    } else {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message.toString()), backgroundColor: Colors.red));

    }
  }

  Future userdata(BuildContext context,String username, String password, String mailid, String unique_id, String platform ) async {

    loginlist.clear();
    // var url = Uri.parse('$baseUrl/user_json5.php');
    var url = Uri.parse('$baseUrl/user_json6.php');
    var data = {
      'username': username.toString(),
      'password': password.toString(),
      'email': mailid.toString(),
      // 'unique_id': unique_id.toString(),
      'platform': platform.toString(),
    }; //to load an rowid  {item is the name used in php file}
    // var response = await http.get(url);
    var response = await http.post(url, body: json.encode(data));
    final items = json.decode(response.body);
    items.forEach((api) {
      final ab = new login_data(
        id: api['id'],
        username: api['username'],
        password: api['password'],
        // unique_id: api['unique_id'],
        user_type: api['user_type'],
        email: api['email_id'],
        companyid: api['companyid'],
        activestatus: api['activestatus'],
        // location_track: api['location_track']??'',
        companystatus: api['companystatus'],
        unique_id: api['unique_id']??'',
        // attendance: api['attendance'],
        // crm: api['crm'],
        // salesorder: api['salesorder'],
        // collection: api['collection'],
        // vehiclemaintenance: api['vehiclemaintenance'],
        // roombooking: api['roombooking'],
        // purchase: api['purchase'],
        // inventory: api['inventory'],
        // task: api['task'],
        // accounts: api['accounts'],
        companyname: api['companyname'],
        // offer: api['offer'],
        logourl: api['logourl'],
        // general: api['general'],
        // settings: api['settings'],
        // profile: api['profile'],
      );
      loginlist.add(ab);
    });
    // SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('id', loginlist[0].id.toString());
    prefs.setString('username', loginlist[0].username.toString());
    prefs.setString('password', loginlist[0].password.toString());
    prefs.setString('email', loginlist[0].email.toString());
    prefs.setString('user_type', loginlist[0].user_type.toString());
    prefs.setString('companyid', loginlist[0].companyid.toString());
    prefs.setString('activestatus', loginlist[0].activestatus.toString());
    // prefs.setString('location_track', loginlist[0].location_track.toString());
    // prefs.setString('attendance', loginlist[0].attendance.toString());
    // prefs.setString('crm', loginlist[0].crm.toString());
    // prefs.setString('salesorder', loginlist[0].salesorder.toString());
    // prefs.setString('collection', loginlist[0].collection.toString());
    // prefs.setString('vehiclemaintenance', loginlist[0].vehiclemaintenance.toString());
    // prefs.setString('roombooking', loginlist[0].roombooking.toString());
    // prefs.setString('purchase', loginlist[0].purchase.toString());
    // prefs.setString('inventory', loginlist[0].inventory.toString());
    // prefs.setString('task', loginlist[0].task.toString());
    // prefs.setString('accounts', loginlist[0].accounts.toString());
    prefs.setString('companyname', loginlist[0].companyname.toString());
    prefs.setString('logourl', loginlist[0].logourl.toString());
    // prefs.setString('offer', loginlist[0].offer.toString());
    // prefs.setString('general', loginlist[0].general.toString());
    // prefs.setString('settings', loginlist[0].settings.toString());
    // prefs.setString('profile', loginlist[0].profile.toString());
    // print('location_track : '+loginlist[0].location_track.toString());
    // print('settings : '+loginlist[0].settings.toString());

    // Save credentials for auto-login
    await AuthService.saveLoginCredentials(
      username: username,
      password: password,
      email: mailid,
      userId: loginlist[0].id.toString(),
    );
    // GoRouter.of(context).pushNamed("dashboard");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerManagementApp()),
    );


  }

}

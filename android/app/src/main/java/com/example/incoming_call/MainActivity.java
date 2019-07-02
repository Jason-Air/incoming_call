package com.example.incoming_call;

// import android.os.Bundle;
// import io.flutter.app.FlutterActivity;
// import io.flutter.plugins.GeneratedPluginRegistrant;

// public class MainActivity extends FlutterActivity {
//   @Override
//   protected void onCreate(Bundle savedInstanceState) {
//     super.onCreate(savedInstanceState);
//     GeneratedPluginRegistrant.registerWith(this);
//   }
// }



import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import java.util.List;

import android.database.Cursor;
import android.provider.CallLog;
import android.Manifest;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private static final String CALLS = "com.example.incoming_call/calls";
  
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    

    new MethodChannel(getFlutterView(), CALLS).setMethodCallHandler(
        new MethodCallHandler() {
          @Override
          public void onMethodCall(MethodCall call, Result result) {
            if (call.method.equals("getCalls")) {
              String calls = getCalls();

              if (calls.length() > 0) {
                result.success(calls);
              } else {
                result.error("UNAVAILABLE", "Calls level not available.", null);
              }
            } else {
              result.notImplemented();
            }
          }
        }
    );
  }

  
  
  private String getCalls() {
 
    StringBuffer sb = new StringBuffer();
    String retResult;
    Cursor managedCursor = managedQuery( CallLog.Calls.CONTENT_URI,null, null,null, null);
    int number = managedCursor.getColumnIndex( CallLog.Calls.NUMBER ); 
    int type = managedCursor.getColumnIndex( CallLog.Calls.TYPE );
    int date = managedCursor.getColumnIndex( CallLog.Calls.DATE);
    int duration = managedCursor.getColumnIndex( CallLog.Calls.DURATION);
    //sb.append( "{\"tel\":[");
    while ( managedCursor.moveToNext() ) {
      String phNumber = managedCursor.getString( number );
      String callType = managedCursor.getString( type );
      //String callDate = managedCursor.getString( date );
      //String callDayTime = managedCursor.getString(callDate);
      String callDuration = managedCursor.getString( duration );
      String dir = null;
      int dircode = Integer.parseInt( callType );
      switch( dircode ) {
        case CallLog.Calls.OUTGOING_TYPE:
        dir = "OUTGOING";
        break;

        case CallLog.Calls.INCOMING_TYPE:
        dir = "INCOMING";
        break;

        case CallLog.Calls.MISSED_TYPE:
        dir = "MISSED";
        break;
      }
      //sb.append( "\nPhone Number:--- "+phNumber +" \nCall Type:--- "+dir+" \nCall duration in sec :--- "+callDuration );
      //sb.append("\n----------------------------------");
      sb.append("\""+phNumber+"\",");
    }
    retResult=sb.toString();
    retResult= retResult.substring(0, retResult.length()-1);
    //retResult=retResult+"]}";
    //retResult=retResult.replace(",]","]");
    //managedCursor.close();
    //call.setText(sb);
    return retResult;
  }
}
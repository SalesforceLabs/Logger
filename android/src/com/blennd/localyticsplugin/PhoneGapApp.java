package com.blennd.localyticsplugin;

import android.app.Activity;

import com.localytics.android.LocalyticsSession;
import com.salesforce.androidsdk.app.ForceApp;
import com.salesforce.androidsdk.ui.SalesforceR;
import com.salesforce.loggr.LoggrGapActivity;
import com.salesforce.loggr.SalesforceRImpl;

// Public Application level class for keeping track of the Localytics Session object
// and other app-wide contexts
public class PhoneGapApp extends ForceApp {
	
	// Declare our localytics session object
	private LocalyticsSession localyticsSession;
	
	private SalesforceR salesforceR = new SalesforceRImpl();
	
	@Override
	public SalesforceR getSalesforceR() {
		return salesforceR;
	}
	
	@Override
	public Class<? extends Activity> getMainActivityClass() {
		return LoggrGapActivity.class;
	}
	
	@Override
	protected String getKey(String name) {
		return null; 
	}

	// Override our onCreate method of the application to create some application wide objects
	@Override
	public void onCreate() {
		super.onCreate();
		
	    // Create a new localytics session
		this.localyticsSession = new LocalyticsSession(
			this.getApplicationContext(), // Context used to access device resources
			"APP KEY FROM STEP 2" // Key generated on the web service
		);
	}
	
	// Public method to get the Localytics Session object
	public LocalyticsSession getLocalyticsSession() {
		return this.localyticsSession;
	}
}

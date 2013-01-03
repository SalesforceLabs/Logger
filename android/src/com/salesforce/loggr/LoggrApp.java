package com.salesforce.loggr;

import android.app.Activity;

import com.localytics.android.LocalyticsSession;
import com.salesforce.androidsdk.app.ForceApp;
import com.salesforce.androidsdk.ui.SalesforceR;

public class LoggrApp extends ForceApp {
	
	private SalesforceR salesforceR = new SalesforceRImpl();
	
	// Declare our localytics session object
	private LocalyticsSession localyticsSession;
	
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
			"${LOCALYTICS_KEY}" // Key generated on the web service
		);
	}
	
	// Public method to get the Localytics Session object
	public LocalyticsSession getLocalyticsSession() {
		return this.localyticsSession;
	}
}

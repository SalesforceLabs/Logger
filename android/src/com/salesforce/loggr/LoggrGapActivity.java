/*
 * Copyright (c) 2011, salesforce.com, inc.
 * All rights reserved.
 * Redistribution and use of this software in source and binary forms, with or
 * without modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * - Neither the name of salesforce.com, inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission of salesforce.com, inc.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package com.salesforce.loggr;

import android.os.Bundle;

import com.localytics.android.LocalyticsSession;
import com.salesforce.androidsdk.ui.SalesforceDroidGapActivity;


/**
 * Application class for the contact explorer.
 * All Salesforce mobile app must extend ForceApp. 
 * ForceApp takes care of intializing the network http clients (among other things).x
 */
public class LoggrGapActivity extends SalesforceDroidGapActivity {


	// Declare our localytics session object
	private LocalyticsSession localyticsSession;
	
	
	@Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        //super.loadUrl("file:///android_asset/www/bootstrap.html");
        
        // Let's get a reference to our application context
        LoggrApp appContext = (LoggrApp) this.getApplicationContext();
        
        // Let's get a reference to our Localytics Session object
        this.localyticsSession = appContext.getLocalyticsSession();

		// Open the session and upload any initialized session data
		this.localyticsSession.open();
		this.localyticsSession.upload();

		// At this point, Localytics Initialization is done. After uploads
		// complete nothing
		// more will happen due to Localytics until the next time you call it.
    }

    /*@Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_main, menu);
        return true;
    }*/
    
    @Override
    public void onResume() {
	    // Call the super
        super.onResume();
        
        // Open the localytics session
        this.localyticsSession.open();
    }

	@Override
	public void onPause() {
		// Close the session and upload the localytics data
		this.localyticsSession.close();
	    this.localyticsSession.upload();
	    
	    // Call the super
		super.onPause();
	}
	
}

package ti.googlesignin

import android.app.Activity
import android.content.Intent
import android.content.pm.ActivityInfo
import android.os.Build
import android.os.Bundle
import org.appcelerator.kroll.common.Log

class TiGoogleSignInActivity : Activity() {

    private var hasShownSignInActivity = false
    private var signInIntent: Intent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        signInIntent = intent.getParcelableExtra("google.sign.in")

        // Allow both landscape- and portrait orientations
        // TODO: Is this correct?
        var orientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT or ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        if (Build.VERSION.SDK_INT >= 9) {
            orientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT or ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        }
        requestedOrientation = orientation

        // Force fullscreen
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN);
        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN);
    }

    override fun onResume() {
        super.onResume()

        if (!hasShownSignInActivity) {
            hasShownSignInActivity = true

            startActivityForResult(signInIntent, 9001)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode === 9001) {
            setResult(requestCode, data)
            finish()
        }
    }

    override fun finish() {
        super.finish()

        if (intent.flags and Intent.FLAG_ACTIVITY_NO_ANIMATION != 0) {
            overridePendingTransition(0, 0)
        }
    }
}
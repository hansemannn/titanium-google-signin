package ti.googlesignin

import android.content.Context
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialInterruptedException
import androidx.credentials.exceptions.NoCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential.Companion.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import org.appcelerator.kroll.KrollDict
import org.appcelerator.titanium.TiApplication
import ti.googlesignin.GooglesigninModule.Companion.ERROR_TYPE_CANCELLED
import ti.googlesignin.GooglesigninModule.Companion.ERROR_TYPE_INTERRUPTED
import ti.googlesignin.GooglesigninModule.Companion.ERROR_TYPE_NO_CREDENTIAL
import ti.googlesignin.GooglesigninModule.Companion.ERROR_TYPE_TOKEN_PARSING
import ti.googlesignin.GooglesigninModule.Companion.LOGIN_TYPE_DIALOG
import ti.googlesignin.GooglesigninModule.Companion.LOGIN_TYPE_SHEET


object TiCredentialManager {
    lateinit var apiKey: String
    private lateinit var credentialManager: CredentialManager

    private fun getContext(): Context {
        return TiApplication.getAppRootOrCurrentActivity()
    }

    private fun createCredentialManager() {
        if (::credentialManager.isInitialized.not()) {
            credentialManager = CredentialManager.create(getContext())
        }
    }

    fun googleSignIn(module: GooglesigninModule, params: KrollDict?) {
        createCredentialManager()

        val loginType = params?.optString("loginType", LOGIN_TYPE_SHEET) ?: LOGIN_TYPE_SHEET

        // If specified, use dialog based sign-in as in previous module. Otherwise use latest bottom-sheet based sign-in.
        val credentialOption = if (loginType == LOGIN_TYPE_DIALOG) {
            GetSignInWithGoogleOption.Builder(apiKey).build()
        } else {
            GetGoogleIdOption.Builder()
                .setFilterByAuthorizedAccounts(params?.optBoolean("filterByAuthorizedAccounts", false) ?: false)
                .setAutoSelectEnabled(params?.optBoolean("autoSelectEnabled", false) ?: false)
                .setRequestVerifiedPhoneNumber(params?.optBoolean("requestVerifiedPhoneNumber", false) ?: false)
                .setServerClientId(apiKey)
                .setNonce(params?.optString("nonce", null))
                .build()
        }

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(credentialOption)
            .build()

        credentialManager.getCredentialAsync(
            context = getContext(),
            request = request,
            cancellationSignal = module.cancellationSignal,
            executor = Runnable::run,
            callback = object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onError(e: GetCredentialException) {
                    onCredentialError(module, e)
                }

                override fun onResult(result: GetCredentialResponse) {
                    onCredentialResult(module, result)
                }
            }
        )
    }

    private fun onCredentialError(module: GooglesigninModule, e: Exception) {
        when (e) {
            // Likely try again with `filterByAuthorizedAccounts: false` if it were `true` previously.
            is NoCredentialException -> module.fireLoginEvent(errorType = ERROR_TYPE_NO_CREDENTIAL, error = e)
            is GetCredentialInterruptedException -> module.fireLoginEvent(errorType = ERROR_TYPE_INTERRUPTED, error = e)
            is GetCredentialCancellationException -> module.fireLoginEvent(cancelled = true, errorType = ERROR_TYPE_CANCELLED, error = e)
            else -> module.fireLoginEvent()
        }
    }

    private fun onCredentialResult(module: GooglesigninModule, result: GetCredentialResponse) {
        val googleCredentials = result.credential
        if (googleCredentials is CustomCredential && googleCredentials.type == TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
            try {
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(googleCredentials.data)
                module.fireLoginEvent(credential = googleIdTokenCredential)

            } catch (e: GoogleIdTokenParsingException) {
                module.fireLoginEvent(errorType = ERROR_TYPE_TOKEN_PARSING, error = e)
            }
        } else {
            module.fireLoginEvent()
        }
    }

    fun signOut(module: GooglesigninModule) {
        createCredentialManager()

        credentialManager.clearCredentialStateAsync(
            request = ClearCredentialStateRequest(),
            cancellationSignal = null,
            executor = Runnable::run,
            callback = object : CredentialManagerCallback<Void?, ClearCredentialException> {
                override fun onError(e: ClearCredentialException) {
                    module.fireLogoutEvent(error = e.errorMessage?.toString() ?: "")
                }

                override fun onResult(result: Void?) {
                    module.fireLogoutEvent(success = true)
                }
            }
        )
    }
}
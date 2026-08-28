package io.nekohasekai.sfa.utils

import libbox.Libbox
import io.nekohasekai.sfa.BuildConfig
import io.nekohasekai.sfa.ktx.unwrap
import java.io.Closeable
import java.util.Locale

class HTTPClient : Closeable {
    companion object {
        val userAgent by lazy {
            var userAgent = "SFA/"
            userAgent += BuildConfig.VERSION_NAME
            userAgent += " ("
            userAgent += BuildConfig.VERSION_CODE
            userAgent += "; sing-box "
            userAgent += Libbox.version()
            userAgent += "; language "
            userAgent += Locale.getDefault().toLanguageTag().replace("-", "_")
            userAgent += ")"
            userAgent
        }
    }

    private val client = Libbox.newHTTPClient()

    init {
        client.modernTLS()
    }

    fun getString(url: String, authToken: String? = null): String {
        val request = client.newRequest()
        request.setUserAgent(userAgent)
        request.setURL(url)
        
        // Add Authorization header if token is provided
        if (!authToken.isNullOrBlank()) {
            request.setHeader("Authorization", "Bearer $authToken")
        }
        
        val response = request.execute()
        return response.content.unwrap
    }

    override fun close() {
        client.close()
    }
}

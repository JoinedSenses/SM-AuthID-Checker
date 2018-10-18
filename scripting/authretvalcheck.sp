#pragma newdecls required
#pragma semicolon 1
#define PLUGIN_NAME "Auth RetVal Checker"
#define PLUGIN_VERSION "1.0"
#include <sourcemod>

bool g_bLateLoad;
bool results[MAXPLAYERS+1];
char g_sFilePath[PLATFORM_MAX_PATH];

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "JoinedSenses",
	description = "Checks return value of getclientauthid",
	version = PLUGIN_VERSION,
	url = "http://github.com/JoinedSenses"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "logs/authcheck");
	
	if (!DirExists(g_sFilePath)) {
		CreateDirectory(g_sFilePath, 511);
		if (!DirExists(g_sFilePath)) {
			SetFailState("Failed to create directory at %s - Please manually create that path and reload this plugin.", g_sFilePath);
		}
	}

	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "/logs/authcheck/RetValChecker.txt");
	
	CreateConVar("sm_authchecker_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				results[i] = true;
			}
		}
	}
}


public void OnClientAuthorized(int client) {
	char steamId[128];
	
	results[client] = GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	if (!results[client] || StrEqual(steamId, "STEAM_ID_STOP_IGNORING_RETVALS")) {
		char clientName[MAX_NAME_LENGTH];
		GetClientName(client, clientName, sizeof(clientName));

		char timeStamp[128];
		FormatTime(timeStamp, sizeof(timeStamp), "%Y-%m-%d %H:%M:%S");

		File file = OpenFile(g_sFilePath, "a+");
		file.WriteLine("%s - OnClientAuthorized Error -  Name: %s Result: %s SteamID: %s", timeStamp, clientName, results[client] ? "true" : "false", steamId);
		delete file;

		KickClient(client, "Error: Authorization failure - Unable to retrieve steamID");
	}
}

public void OnClientPutInServer(int client) {
	if (!IsClientAuthorized(client) || !results[client]) {
		char steamId[128];
		results[client] = GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		char clientName[MAX_NAME_LENGTH];
		GetClientName(client, clientName, sizeof(clientName));

		char timeStamp[128];
		FormatTime(timeStamp, sizeof(timeStamp), "%Y-%m-%d %H:%M:%S");

		File file = OpenFile(g_sFilePath, "a+");
		file.WriteLine("%s - OnClientPutInServer Error -  Name: %s Result: %s SteamID: %s", timeStamp, clientName, results[client] ? "true" : "false", steamId);
		delete file;

		KickClient(client, "Error: Authorization failure. Please try reconnecting.");
	}
	else {
		results[client] = true;
	}
}

public void OnClientDisconnect(int client) {
	results[client] = false;
}
extends Node

const SUPABASE_URL := "https://kkorcssqgohsgqhhqpbu.supabase.co"
const SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtrb3Jjc3NxZ29oc2dxaGhxcGJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NjI1MzYsImV4cCI6MjA5NDUzODUzNn0.KaInqVmAVXf3F3HcJcrmWT2svB1bDdTipKfESvC7R54"

const UPSERT_PATH := "/functions/v1/upsert-score"
const LEADERBOARD_PATH := "/functions/v1/get-leaderboard"

const REQUEST_TIMEOUT_SECONDS := 15.0

signal score_submitted(is_new_record: bool)
signal leaderboard_received(data: Dictionary)

enum RequestKind { NONE, SUBMIT, LEADERBOARD }

var last_leaderboard: Dictionary = _empty_leaderboard()

var _http: HTTPRequest
var _current_request: RequestKind = RequestKind.NONE


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.use_threads = false
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


func submit_score(p_display_name: String, p_difficulty: String, p_score: int) -> void:
	if _current_request != RequestKind.NONE:
		_http.cancel_request()

	_current_request = RequestKind.SUBMIT

	var body := {
		"display_name": p_display_name,
		"difficulty": p_difficulty,
		"score": maxi(p_score, 0),
	}
	var headers := _auth_headers()
	headers.append("Content-Type: application/json")

	var err := _http.request(
		SUPABASE_URL + UPSERT_PATH,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if err != OK:
		push_warning("RankingAPI.submit_score request error: %s" % err)
		_current_request = RequestKind.NONE
		score_submitted.emit(false)


func fetch_leaderboard() -> void:
	if _current_request != RequestKind.NONE:
		_http.cancel_request()

	_current_request = RequestKind.LEADERBOARD

	var err := _http.request(
		SUPABASE_URL + LEADERBOARD_PATH,
		_auth_headers(),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		push_warning("RankingAPI.fetch_leaderboard request error: %s" % err)
		_current_request = RequestKind.NONE
		last_leaderboard = _empty_leaderboard()
		leaderboard_received.emit(last_leaderboard)


func _auth_headers() -> PackedStringArray:
	return PackedStringArray([
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % SUPABASE_ANON_KEY,
	])


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
) -> void:
	var kind := _current_request
	_current_request = RequestKind.NONE

	var network_ok := result == HTTPRequest.RESULT_SUCCESS
	var http_ok := response_code == 200 or response_code == 201
	var success := network_ok and http_ok

	var payload: Variant = null
	if body.size() > 0:
		payload = JSON.parse_string(body.get_string_from_utf8())

	if not success:
		push_warning(
			"RankingAPI request failed (result=%d, code=%d): %s"
			% [result, response_code, body.get_string_from_utf8()]
		)

	match kind:
		RequestKind.SUBMIT:
			var is_new_record := false
			if success and payload is Dictionary:
				is_new_record = bool(payload.get("is_new_record", false))
			score_submitted.emit(is_new_record)
		RequestKind.LEADERBOARD:
			var data := _empty_leaderboard()
			if success and payload is Dictionary:
				var raw: Variant = payload.get("data", null)
				if raw is Dictionary:
					for key in data.keys():
						var bucket: Variant = raw.get(key, null)
						if bucket is Array:
							data[key] = _normalize_entries(bucket)
			last_leaderboard = data
			leaderboard_received.emit(data)
		RequestKind.NONE:
			pass


func _normalize_entries(raw_entries: Array) -> Array:
	var entries: Array = []
	for raw_entry in raw_entries:
		if not (raw_entry is Dictionary):
			continue
		entries.append({
			"rank": int(raw_entry.get("rank", 0)),
			"display_name": String(raw_entry.get("display_name", "")),
			"highscore": int(raw_entry.get("highscore", 0)),
		})
	return entries


func _empty_leaderboard() -> Dictionary:
	return {
		"easy": [],
		"medium": [],
		"hard": [],
		"impossible": [],
	}

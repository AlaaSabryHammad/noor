package app.noor.noor

import com.ryanheise.audioservice.AudioServiceActivity

// Shares its Flutter engine with audio_service so playback controls in the
// notification and on the lock screen reach the running app.
class MainActivity : AudioServiceActivity()

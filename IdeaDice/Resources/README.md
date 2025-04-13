# Ambient Sound Resources

This directory should contain MP3 files for ambient sounds used in the Focus Mode feature.

## Required Audio Files

Place the following MP3 files in this directory:

1. `rain_ambient.mp3` - Gentle rain sounds
2. `coffee_shop_ambient.mp3` - Coffee shop ambiance
3. `nature_ambient.mp3` - Nature sounds (birds, light wind)
4. `fireplace_ambient.mp3` - Crackling fireplace
5. `flute_ambient.mp3` - Calming flute melody

## Audio File Requirements

- Files should be in MP3 format
- Files should be loopable without noticeable breaks or gaps
- Keep file sizes reasonable (1-3MB each is ideal)
- Aim for 2-5 minutes of audio that loops seamlessly
- For best results, use audio files with smooth fade-in/fade-out at boundaries
- Audio should be mastered at a consistent volume level across all tracks

## Looping Behavior

The app is configured to automatically loop each audio track indefinitely when selected. The `AVAudioPlayer` handles this looping internally with the following characteristics:

- Tracks will continue playing until the user changes sounds or turns off the feature
- If audio playback is interrupted (e.g., by a phone call or system notification), the app will attempt to resume playback automatically
- The app maintains the selected audio and volume settings between sessions

## Sources for Audio Files

You can obtain suitable ambient sound files from:

1. Royalty-free sound websites like FreeSound.org or Pixabay
2. Stock audio libraries like Epidemic Sound or Artlist
3. Creating your own recordings with proper audio editing for seamless loops
4. Specialized ambient sound apps that offer exportable tracks

Make sure you have the appropriate rights to use any audio files you include in the app.

## Implementation Notes

The app will look for these specific filenames in this directory, so ensure they match exactly. If files are missing, the corresponding ambient sound option will still appear in the menu but will not play anything when selected. For the best user experience, include all the listed audio files. 
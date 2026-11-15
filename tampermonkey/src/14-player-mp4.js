  // Keep the download UI inside the player so it remains visible in fullscreen.
  (() => {
    let button;
    let audioButton;
    let transcriptButton;
    const panels = { mp4: null, mp3: null };
    let panelVideoId = paramsVideoURL();
    const element = (tag, className, text) => {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text) node.textContent = text;
      return node;
    };

    function closePanel() {
      for (const panel of Object.values(panels)) if (panel) panel.hidden = true;
      if (button) button.setAttribute('aria-expanded', 'false');
      if (audioButton) audioButton.setAttribute('aria-expanded', 'false');
    }

    function createPanel(player, format) {
      const panel = element('section', 'yt-tools-player-download');
      panel.id = format === 'mp4' ? 'yt-tools-player-download' : 'yt-tools-player-audio-download';
      panels[format] = panel;
      panel.setAttribute('role', 'dialog');
      panel.setAttribute('aria-label', format === 'mp4' ? 'Download video' : 'Download audio');
      panel.hidden = true;
      const header = element('div', 'yt-tools-player-download-header');
      header.appendChild(element('strong', '', `Download ${format.toUpperCase()}`));
      const close = element('button', 'yt-tools-player-close', '×');
      close.type = 'button';
      close.setAttribute('aria-label', 'Close download panel');
      close.addEventListener('click', closePanel);
      header.appendChild(close);
      panel.appendChild(header);
      const box = element('div', 'download-container yt-tools-player-download-box');
      box.dataset.type = format === 'mp4' ? 'video' : 'audio';
      box.hidden = true;
      const text = element('span', 'download-text', format === 'mp4' ? 'Download video' : 'Download audio');
      const quality = element('span', 'download-quality');
      const download = element('button', 'download-btn', 'Download');
      download.type = 'button';
      const retry = element('button', 'retry-btn', 'Retry');
      retry.type = 'button'; retry.style.display = 'none';
      const progressRetry = element('button', 'progress-retry-btn', 'Retry');
      progressRetry.type = 'button'; progressRetry.style.display = 'none';
      const again = element('button', 'download-again-btn', 'Download again');
      again.type = 'button'; again.style.display = 'none';
      const progress = element('div', 'progress-container'); progress.style.display = 'none';
      const bar = element('div', 'progress-bar');
      bar.appendChild(element('div', 'progress-fill'));
      progress.append(bar, element('span', 'progress-text', '0%'));
      box.append(text, quality, download, retry, progressRetry, again, progress);
      panel.appendChild(box);
      panel.addEventListener('click', event => {
        const target = event.target.closest('button');
        if (target && box.contains(target)) {
          event.preventDefault();
          if (target === again) { if (box.dataset.lastDownloadUrl) window.open(box.dataset.lastDownloadUrl); }
          else if (box.dataset.quality) {
            if (target === progressRetry) box.dataset.downloading = 'false';
            startDownloadVideoOrAudio(box.dataset.quality, box);
          }
        }
        event.stopPropagation();
      });
      panel.addEventListener('keydown', event => {
        if (event.key === 'Escape') { closePanel(); (format === 'mp4' ? button : audioButton)?.focus(); event.stopPropagation(); }
      });
      player.appendChild(panel);
      return panel;
    }

    function toggleDownload(player, format) {
      const trigger = format === 'mp4' ? button : audioButton;
      let panel = panels[format];
      if (!panel || panel.parentElement !== player) panel = createPanel(player, format);
      const willOpen = panel.hidden;
      closePanel();
      if (!willOpen) return;
      panel.hidden = false;
      trigger.setAttribute('aria-expanded', 'true');
      const box = panel.querySelector('.download-container');
      if (box.dataset.started) return;
      const configured = readJsonGM('ytSettingsMDCM', {}).defaultMp4Quality;
      const quality = format === 'mp3' ? 'mp3' :
        (['144', '240', '360', '480', '720', '1080'].includes(configured) ? configured : '720');
      box.dataset.started = 'true';
      box.dataset.quality = quality;
      box.hidden = false;
      box.querySelector('.download-quality').textContent = format === 'mp3' ? ' MP3' : ` ${quality}p MP4`;
      startDownloadVideoOrAudio(quality, box);
    }

    function ensurePlayerButton() {
      const player = document.querySelector('#movie_player');
      const controls = player?.querySelector('.ytp-left-controls');
      const play = controls?.querySelector('.ytp-play-button');
      if (!player || !controls || !play) return;
      if (button?.parentElement !== controls) {
        button = element('button', 'ytp-button yt-tools-player-mp4', 'MP4');
        button.id = 'yt-tools-player-mp4';
        button.type = 'button';
        button.title = 'Download video (MP4)';
        button.setAttribute('aria-label', 'Download video (MP4)');
        button.setAttribute('aria-expanded', 'false');
        button.setAttribute('aria-controls', 'yt-tools-player-download');
        button.addEventListener('click', event => {
          event.preventDefault(); event.stopPropagation();
          toggleDownload(player, 'mp4');
        });
        play.insertAdjacentElement('afterend', button);
      }
      const settings = readJsonGM('ytSettingsMDCM', {});
      button.hidden = settings.btnDownloadMp4 === false;
      if (audioButton?.parentElement !== controls) {
        audioButton = element('button', 'ytp-button yt-tools-player-mp3', 'MP3');
        audioButton.id = 'yt-tools-player-mp3';
        audioButton.type = 'button';
        audioButton.title = 'Download audio (MP3)';
        audioButton.setAttribute('aria-label', 'Download audio (MP3)');
        audioButton.setAttribute('aria-expanded', 'false');
        audioButton.setAttribute('aria-controls', 'yt-tools-player-audio-download');
        audioButton.addEventListener('click', event => {
          event.preventDefault(); event.stopPropagation();
          toggleDownload(player, 'mp3');
        });
        button.insertAdjacentElement('afterend', audioButton);
      }
      audioButton.hidden = settings.btnDownloadMp3 === false;
      if (transcriptButton?.parentElement !== controls) {
        transcriptButton = element('button', 'ytp-button yt-tools-player-transcript', 'Transcript ↓');
        transcriptButton.type = 'button';
        transcriptButton.id = 'yt-tools-player-transcript';
        transcriptButton.title = 'Download transcript as Markdown';
        transcriptButton.setAttribute('aria-label', 'Download transcript as Markdown');
        transcriptButton.addEventListener('click', async event => {
          event.preventDefault(); event.stopPropagation();
          if (transcriptButton.disabled) return;
          const currentButton = transcriptButton;
          currentButton.disabled = true;
          currentButton.textContent = 'Loading…';
          const status = element('div', 'yt-tools-transcript-status', 'Preparing transcript…');
          status.setAttribute('role', 'status');
          player.appendChild(status);
          try {
            await ytTranscriptDownloadDefault();
            status.textContent = 'Transcript downloaded';
          } catch (error) {
            status.textContent = error.message || 'Could not download transcript.';
            console.warn('[YouTube Tools] transcript download:', error);
          } finally {
            currentButton.disabled = false;
            currentButton.textContent = 'Transcript ↓';
            setTimeout(() => status.remove(), 6000);
          }
        });
        audioButton.insertAdjacentElement('afterend', transcriptButton);
      }
      transcriptButton.hidden = settings.btnTranscript === false;
    }

    let scheduled = false;
    const observer = new MutationObserver(() => {
      if (scheduled) return;
      const controls = document.querySelector('#movie_player .ytp-left-controls');
      if (controls && button?.parentElement === controls && audioButton?.parentElement === controls && transcriptButton?.parentElement === controls) return;
      scheduled = true;
      requestAnimationFrame(() => { scheduled = false; ensurePlayerButton(); });
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
    document.addEventListener('yt-navigate-start', closePanel);
    document.addEventListener('yt-navigate-finish', () => {
      const currentVideoId = paramsVideoURL();
      if (currentVideoId !== panelVideoId) {
        for (const format of ['mp4', 'mp3']) {
          const panel = panels[format];
          if (panel) { resetDownloadState(panel.querySelector('.download-container')); panel.remove(); panels[format] = null; }
        }
        panelVideoId = currentVideoId;
      }
      ensurePlayerButton();
    });
    ensurePlayerButton();
  })();

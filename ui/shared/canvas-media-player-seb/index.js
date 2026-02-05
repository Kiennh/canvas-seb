/*
 * Copyright (C) 2026 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import { MediaPlayer } from '@instructure/ui-media-player'

/**
 * SEB Media Player Customization
 * 
 * This module applies custom styling and behavior to media players when accessed 
 * through Safe Exam Browser (SEB). It hooks into React.createElement to 
 * inject the hideControls prop into MediaPlayer components when restricted.
 */


// Capture SEB settings immediately and freeze them to prevent end-user tampering via console
const SEB_LOCKED_SETTINGS = Object.freeze({
    hideAll: !!(window.ENV?.SEB_HIDE_ALL_MEDIA_CONTROLS),
    disableSeek: !!(window.ENV?.SEB_DISABLE_MEDIA_SEEK)
})

// We attempt to hook both the global React and the imported one
const reactHooks = [window.React, React].filter(r => r && r.createElement)

reactHooks.forEach((R, index) => {
    try {
        const originalCreateElement = R.createElement

        R.createElement = function (type, props, ...children) {
            if (!type) return originalCreateElement.apply(this, [type, props, ...children])

            // Get component name safely
            const name = type.displayName || type.name || (typeof type === 'string' ? type : '')

            // 1. Handle "Hide All Controls" via the official hideControls prop on MediaPlayer
            if (name === 'MediaPlayer' || name === 'MediaPlayerComponent') {
                if (SEB_LOCKED_SETTINGS.hideAll) {
                    // Create a new props object and lock the hideControls property
                    const newProps = Object.assign({}, props)
                    Object.defineProperty(newProps, 'hideControls', {
                        value: true,
                        writable: false,
                        configurable: false,
                        enumerable: true
                    })
                    return originalCreateElement.apply(this, [type, newProps, ...children])
                }
            }

            // 2. Handle "Disable Seek" by hiding specific sub-components
            if (SEB_LOCKED_SETTINGS.disableSeek) {
                const seekRelatedNames = ['Timebar', 'Volume', 'PlayerSettings', 'FullScreenButton', 'CaptionsToggle']
                if (seekRelatedNames.some(seekName => name.includes(seekName))) {
                    return null
                }
            }

            return originalCreateElement.apply(this, [type, props, ...children])
        }
    } catch (e) {
        // Silent
    }
})

export function applySebMediaPlayerStyles() {
    // Check if we're in SEB context (now just checks if plugin is enabled/restrictions active)
    const isSebActive = window.ENV?.SEB_ENABLED

    if (!isSebActive) {
        return
    }

    // Get plugin settings from ENV
    const hideAllControls = window.ENV?.SEB_HIDE_ALL_MEDIA_CONTROLS
    const disableSeek = window.ENV?.SEB_DISABLE_MEDIA_SEEK

    // Determine which CSS class to apply (Fallback for non-React players)
    let cssClass = null
    if (hideAllControls) {
        cssClass = 'hide-all-controls'
    } else if (disableSeek) {
        cssClass = 'disable-seek'
    }

    if (!cssClass) return

    // Apply CSS classes as fallback/legacy support
    const applyStylesToPlayers = () => {
        const mediaPlayerContainers = document.querySelectorAll('[data-tracks]')
        mediaPlayerContainers.forEach(container => {
            if (!container.classList.contains(cssClass)) {
                container.classList.add('seb-media-player')
                container.classList.add(cssClass)
            }
        })
    }

    applyStylesToPlayers()

    const observer = new MutationObserver(applyStylesToPlayers)
    observer.observe(document.body, { childList: true, subtree: true })

    return observer
}

// Auto-initialize
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applySebMediaPlayerStyles)
} else {
    applySebMediaPlayerStyles()
}

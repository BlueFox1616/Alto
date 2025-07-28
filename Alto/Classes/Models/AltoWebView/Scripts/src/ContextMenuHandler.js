function findNearestMediaOrText(el) {
  while (el) {
	if (el.nodeType === Node.TEXT_NODE) {
	  el = el.parentElement;
	  continue;
	}

	if (el.tagName === "IMG") return el;
	if (el.tagName === "VIDEO") return el;

	if (el.tagName === "A") {
	  const img = el.querySelector("img");
	  return img || el;
	}

	if (el.textContent && el.textContent.trim().length > 0) {
	  return el;
	}

	el = el.parentElement;
  }
  return null;
}

window.oncontextmenu = function(event) {
  event.preventDefault();

  const selectedText = window.getSelection().toString().trim();
  const found = findNearestMediaOrText(event.target);

  let message = null;

  if (selectedText) {
	message = {
	  type: "text",
	  value: selectedText,
	};
  } else if (found) {
	if (found.tagName === "IMG") {
	  message = {
		type: "image",
		value: found.src,
	  };
	} else if (found.tagName === "VIDEO") {
	  const videoSrc = found.src || (found.querySelector('source')?.src) || null;
	  message = {
		type: "video",
		value: videoSrc || "no-src",
	  };
	} else if (found.tagName === "A") {
	  message = {
		type: "link",
		value: found.href,
	  };
	} else {
	  message = {
		type: "text",
		value: found.textContent.trim(),
	  };
	}
  } else {
	message = {
	  type: "unknown",
	  value: "",
	};
  }


  if (window.webkit?.messageHandlers?.menuHandler) {
	window.webkit.messageHandlers.menuHandler.postMessage(message);
  } else {
	console.log("Handler not found", message);
  }

  return false;
};

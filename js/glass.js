/* Aurora Glass — interactions. Vanilla, zero deps. */
(function () {
  "use strict";
  const $ = (s, c = document) => c.querySelector(s);
  const $$ = (s, c = document) => [...c.querySelectorAll(s)];

  /* ---- auto-number every demo + fill section counts ---- */
  let n = 0;
  $$(".demo").forEach((d) => {
    n += 1;
    const i = $(".demo-num i", d);
    if (i) i.textContent = "#" + String(n).padStart(3, "0");
  });
  const total = n;
  $$(".section").forEach((sec) => {
    const c = $$(".demo", sec).length;
    const el = $(".count", sec);
    if (el) el.textContent = c + " components";
    const link = $(`.rail a[href="#${sec.id}"] .n`);
    if (link) link.textContent = c;
  });
  animateNum($("#stat-components"), total);

  /* ---- animated number ---- */
  function animateNum(el, to, dur = 1400) {
    if (!el) return;
    const t0 = performance.now();
    (function tick(t) {
      const p = Math.min((t - t0) / dur, 1);
      el.textContent = Math.round(to * (1 - Math.pow(1 - p, 3)));
      if (p < 1) requestAnimationFrame(tick);
    })(t0);
  }
  const seen = new WeakSet();
  const cntIO = new IntersectionObserver((es) => es.forEach((e) => {
    if (e.isIntersecting && !seen.has(e.target)) {
      seen.add(e.target);
      animateNum(e.target, +e.target.dataset.count);
    }
  }), { threshold: 0.6 });
  $$("[data-count]").forEach((el) => cntIO.observe(el));

  /* ---- theme toggle ---- */
  const themeBtn = $("#theme-btn");
  themeBtn.addEventListener("click", () => {
    const html = document.documentElement;
    const next = html.dataset.theme === "dark" ? "light" : "dark";
    html.dataset.theme = next;
    themeBtn.textContent = next === "dark" ? "☾" : "☀";
  });

  /* ---- cursor spotlight ---- */
  document.addEventListener("pointermove", (e) => {
    const el = e.target.closest(".spot");
    if (!el) return;
    const r = el.getBoundingClientRect();
    el.style.setProperty("--mx", e.clientX - r.left + "px");
    el.style.setProperty("--my", e.clientY - r.top + "px");
  });

  /* ---- button ripple ---- */
  document.addEventListener("click", (e) => {
    const b = e.target.closest(".btn, .fab");
    if (!b) return;
    const r = b.getBoundingClientRect();
    const s = document.createElement("span");
    const size = Math.max(r.width, r.height);
    s.className = "ripple";
    s.style.cssText = `width:${size}px;height:${size}px;left:${e.clientX - r.left - size / 2}px;top:${e.clientY - r.top - size / 2}px`;
    b.appendChild(s);
    setTimeout(() => s.remove(), 600);
  });

  /* ---- segmented control thumb ---- */
  $$("[data-seg]").forEach((seg) => {
    const thumb = $(".thumb", seg);
    const move = (btn) => {
      thumb.style.left = btn.offsetLeft + "px";
      thumb.style.width = btn.offsetWidth + "px";
    };
    move($("button.on", seg));
    $$("button", seg).forEach((b) =>
      b.addEventListener("click", () => {
        $$("button", seg).forEach((x) => x.classList.remove("on"));
        b.classList.add("on");
        move(b);
      })
    );
  });

  /* ---- tabs ---- */
  $$("[data-tabs]").forEach((t) =>
    $$("button", t).forEach((b) =>
      b.addEventListener("click", () => {
        $$("button", t).forEach((x) => x.classList.remove("on"));
        b.classList.add("on");
      })
    )
  );

  /* ---- accordion ---- */
  $$("[data-acc] .a-head").forEach((h) =>
    h.addEventListener("click", () => {
      const item = h.parentElement;
      const open = item.classList.contains("open");
      $$(".a-item", item.parentElement).forEach((i) => i.classList.remove("open"));
      if (!open) item.classList.add("open");
    })
  );

  /* ---- range readout ---- */
  $$(".grange").forEach((r) =>
    r.addEventListener("input", () => {
      r.style.setProperty("--val", r.value + "%");
      const out = $("#range-out");
      if (out) out.textContent = r.value;
    })
  );

  /* ---- rating ---- */
  $$("[data-rate]").forEach((rate) => {
    const btns = $$("button", rate);
    const paint = (k) => btns.forEach((b, i) => b.classList.toggle("lit", i < k));
    paint(+rate.dataset.rate);
    btns.forEach((b, i) => b.addEventListener("click", () => paint(i + 1)));
  });

  /* ---- stepper ---- */
  $$(".stepper button").forEach((b) =>
    b.addEventListener("click", () => {
      const v = $(".val", b.parentElement);
      v.textContent = Math.max(0, +v.textContent + +b.dataset.step);
    })
  );

  /* ---- swatches ---- */
  $$(".swatches").forEach((g) =>
    $$(".swatch", g).forEach((s) =>
      s.addEventListener("click", () => {
        $$(".swatch", g).forEach((x) => x.classList.remove("on"));
        s.classList.add("on");
      })
    )
  );

  /* ---- OTP auto-advance ---- */
  $$(".otp").forEach((o) => {
    const cells = $$("input", o);
    cells.forEach((c, i) => {
      c.addEventListener("input", () => c.value && cells[i + 1]?.focus());
      c.addEventListener("keydown", (e) => e.key === "Backspace" && !c.value && cells[i - 1]?.focus());
    });
  });

  /* ---- overlay system ---- */
  const scrim = $("#scrim");
  let openEls = [];
  const open = (id, lite) => {
    const el = $("#" + id);
    if (!el) return;
    if (!lite) scrim.classList.add("open");
    el.classList.add("open");
    openEls.push(el);
  };
  const closeAll = () => {
    openEls.forEach((e) => e.classList.remove("open"));
    openEls = [];
    scrim.classList.remove("open");
  };
  $$("[data-open]").forEach((b) => b.addEventListener("click", () => open(b.dataset.open)));
  $$("[data-close]").forEach((b) => b.addEventListener("click", closeAll));
  scrim.addEventListener("click", closeAll);
  $(".lightbox")?.addEventListener("click", closeAll);

  /* ---- toasts ---- */
  const TOASTS = {
    ok: ["✓", "Pane frosted", "Backdrop locked at blur(36px)"],
    warn: ["⚠", "Heavy refraction", "Composite cost rising on this pane"],
    err: ["✕", "Lens error", "SVG filter unsupported — using blur"],
    info: ["ⓘ", "Heads up", "New tint ramp shipped in v3.1"],
  };
  document.addEventListener("click", (e) => {
    const t = e.target.closest("[data-toast]");
    if (!t) return;
    const kind = t.dataset.toast;
    const [icon, title, body] = TOASTS[kind];
    const el = document.createElement("div");
    el.className = `toast glass-3 ${kind}`;
    el.innerHTML = `<span class="t-ic">${icon}</span><div class="t-body"><b>${title}</b><span>${body}</span></div><button class="t-x">✕</button>`;
    $("#toasts").appendChild(el);
    const kill = () => { el.classList.add("out"); setTimeout(() => el.remove(), 300); };
    $(".t-x", el).addEventListener("click", kill);
    setTimeout(kill, 4200);
  });

  /* ---- context menu ---- */
  const ctx = $("#ctx-menu");
  const ctxBtn = $("#ctx-btn");
  const showCtx = (x, y) => {
    ctx.style.display = "flex";
    ctx.style.left = Math.min(x, innerWidth - 220) + "px";
    ctx.style.top = y + "px";
  };
  ctxBtn.addEventListener("contextmenu", (e) => { e.preventDefault(); showCtx(e.clientX, e.clientY); });
  ctxBtn.addEventListener("click", (e) => { const r = ctxBtn.getBoundingClientRect(); showCtx(r.left, r.bottom + 8); });
  document.addEventListener("click", (e) => { if (!e.target.closest("#ctx-menu, #ctx-btn")) ctx.style.display = "none"; });
  $$("#ctx-menu a").forEach((a) => a.addEventListener("click", () => (ctx.style.display = "none")));

  /* ---- command palette ---- */
  const palette = $("#palette");
  const pInput = $("#palette-input");
  const pList = $("#palette-list");
  const items = $$(".section").flatMap((sec) =>
    $$(".demo-num span", sec).map((s) => ({ name: s.textContent.toLowerCase().replaceAll("·", " "), sec: sec.id }))
  );
  const render = (q = "") => {
    const list = items.filter((i) => i.name.includes(q)).slice(0, 9);
    pList.innerHTML = list
      .map((i, k) => `<div class="p-item${k === 0 ? " on" : ""}" data-sec="${i.sec}"><span class="pi">◈</span>${i.name}<span class="sc">jump ↵</span></div>`)
      .join("") || `<div class="p-item">No components match</div>`;
  };
  const togglePalette = (on) => {
    palette.classList.toggle("open", on);
    scrim.classList.toggle("open", on || openEls.length > 0);
    if (on) { render(); pInput.value = ""; setTimeout(() => pInput.focus(), 60); }
  };
  $("#palette-btn").addEventListener("click", () => togglePalette(true));
  $("#palette-btn-2").addEventListener("click", () => togglePalette(true));
  pInput.addEventListener("input", () => render(pInput.value.trim().toLowerCase()));
  pList.addEventListener("click", (e) => {
    const it = e.target.closest(".p-item[data-sec]");
    if (!it) return;
    togglePalette(false);
    $("#" + it.dataset.sec)?.scrollIntoView({ behavior: "smooth" });
  });
  document.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") { e.preventDefault(); togglePalette(!palette.classList.contains("open")); }
    if (e.key === "Escape") { togglePalette(false); closeAll(); }
    if (e.key === "Enter" && palette.classList.contains("open")) $(".p-item.on")?.click();
  });

  /* ---- scrollspy + reveal ---- */
  const links = $$(".rail a");
  const spyIO = new IntersectionObserver((es) => es.forEach((en) => {
    if (!en.isIntersecting) return;
    links.forEach((l) => l.classList.toggle("on", l.hash === "#" + en.target.id));
  }), { rootMargin: "-30% 0px -55% 0px" });
  $$(".section").forEach((s) => spyIO.observe(s));

  const revIO = new IntersectionObserver((es) => es.forEach((e) => {
    if (e.isIntersecting) { e.target.classList.add("in"); revIO.unobserve(e.target); }
  }), { threshold: 0.12 });
  $$(".reveal, .demo").forEach((el) => { el.classList.add("reveal"); revIO.observe(el); });

  /* ---- tilt ---- */
  $$("[data-tilt]").forEach((el) => {
    el.addEventListener("pointermove", (e) => {
      const r = el.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5;
      const y = (e.clientY - r.top) / r.height - 0.5;
      el.style.transform = `perspective(700px) rotateX(${-y * 9}deg) rotateY(${x * 11}deg) translateZ(6px)`;
    });
    el.addEventListener("pointerleave", () => (el.style.transform = ""));
  });

  /* ---- glow card border sweep ---- */
  let ga = 0;
  (function sweep() {
    ga = (ga + 0.6) % 360;
    $$(".glowcard").forEach((el) => el.style.setProperty("--ga", ga + "deg"));
    requestAnimationFrame(sweep);
  })();

  /* ---- copy field ---- */
  $$("[data-copy]").forEach((b) =>
    b.addEventListener("click", () => {
      navigator.clipboard?.writeText($(".grow", b.parentElement).textContent.trim());
      b.textContent = "✓ Copied";
      setTimeout(() => (b.textContent = "⧉ Copy"), 1600);
    })
  );

  /* ---- dismissible alerts ---- */
  $$(".a-x").forEach((x) => x.addEventListener("click", () => {
    const a = x.closest(".alert");
    a.style.transition = "all .3s";
    a.style.opacity = 0;
    a.style.transform = "translateY(-6px)";
    setTimeout(() => (a.style.display = "none"), 300);
  }));

  /* ================================================================
     INTERACTION LAYER — every demo responds to press / type / hover
     ================================================================ */

  const toast = (kind, title, body) => {
    const [icon] = (TOASTS[kind] || TOASTS.info);
    const el = document.createElement("div");
    el.className = `toast glass-3 ${kind}`;
    el.innerHTML = `<span class="t-ic">${icon}</span><div class="t-body"><b>${title}</b><span>${body}</span></div><button class="t-x">✕</button>`;
    $("#toasts").appendChild(el);
    const kill = () => { el.classList.add("out"); setTimeout(() => el.remove(), 300); };
    $(".t-x", el).addEventListener("click", kill);
    setTimeout(kill, 3600);
  };

  /* ---- chips / file chips: ✕ removes ---- */
  document.addEventListener("click", (e) => {
    const x = e.target.closest(".chip .x, .file-chip .x, .tagbox .x");
    if (!x) return;
    const chip = x.closest(".chip, .file-chip");
    chip.style.cssText += ";transform:scale(.5);opacity:0;transition:all .18s";
    setTimeout(() => chip.remove(), 190);
  });

  /* ---- tagbox: Enter creates a chip ---- */
  const chipTints = ["glass-indigo", "glass-cyan", "glass-pink", "glass-amber", "glass-green"];
  let chipI = 0;
  $$(".tagbox input").forEach((inp) =>
    inp.addEventListener("keydown", (e) => {
      if (e.key !== "Enter" || !inp.value.trim()) return;
      const chip = document.createElement("span");
      chip.className = "chip " + chipTints[chipI++ % chipTints.length];
      chip.innerHTML = inp.value.trim() + ' <button class="x">✕</button>';
      inp.parentElement.insertBefore(chip, inp);
      inp.value = "";
    })
  );

  /* ---- live countdown ---- */
  $$(".countdown").forEach((cd) => {
    const bs = $$(".cd b", cd);
    if (bs.length < 4) return;
    let t = (+bs[0].textContent) * 86400 + (+bs[1].textContent) * 3600 + (+bs[2].textContent) * 60 + (+bs[3].textContent);
    const paint = () => [Math.floor(t / 86400), Math.floor(t % 86400 / 3600), Math.floor(t % 3600 / 60), t % 60]
      .forEach((v, i) => (bs[i].textContent = String(v).padStart(2, "0")));
    paint();
    setInterval(() => { t = Math.max(0, t - 1); paint(); }, 1000);
  });

  /* ---- password peek ---- */
  $$(".peek").forEach((b) =>
    b.addEventListener("click", () => {
      const inp = $("input", b.parentElement);
      if (!inp) return;
      const show = inp.type === "password";
      inp.type = show ? "text" : "password";
      b.textContent = show ? "◌" : "◉";
    })
  );

  /* ---- independent toggle groups (B/I/U/S) ---- */
  $$("[data-tgroup]").forEach((g) =>
    $$("button", g).forEach((b) => b.addEventListener("click", () => b.classList.toggle("on")))
  );

  /* ---- speed dial: tap toggles too (touch) ---- */
  $$(".speed").forEach((s) =>
    $(".fab.glass-indigo", s)?.addEventListener("click", () => s.classList.toggle("open"))
  );

  /* ---- single-select nav rails ---- */
  $$(".bottombar, .menubar, .dotnav, .topnav nav, .rail-demo nav").forEach((nav) =>
    $$("a", nav).forEach((a) =>
      a.addEventListener("click", (e) => {
        e.preventDefault();
        $$("a", nav).forEach((x) => x.classList.remove("on"));
        a.classList.add("on");
      })
    )
  );

  /* ---- pagination: ‹ › walk the selection ---- */
  $$(".pager").forEach((p) =>
    $$("a", p).forEach((a, i, all) =>
      a.addEventListener("click", (e) => {
        e.preventDefault();
        const cur = Math.max(1, all.findIndex((x) => x.classList.contains("on")));
        const t = a.textContent.trim();
        let next = t === "‹" ? cur - 1 : t === "›" ? cur + 1 : i;
        next = Math.max(1, Math.min(all.length - 2, next));
        if (all[next].textContent.trim() === "…") next = cur;
        all.forEach((x) => x.classList.remove("on"));
        all[next].classList.add("on");
      })
    )
  );

  /* ---- calendar day select ---- */
  $$(".cal").forEach((cal) =>
    $$(".day", cal).forEach((d) =>
      d.addEventListener("click", () => {
        if (d.classList.contains("dim")) return;
        $$(".day.sel", cal).forEach((x) => x.classList.remove("sel"));
        d.classList.add("sel");
      })
    )
  );

  /* ---- notifications: click marks read ---- */
  $$(".note-item.unread").forEach((n) =>
    n.addEventListener("click", () => n.classList.remove("unread"))
  );

  /* ---- combobox: live filter + pick ---- */
  $$(".combo-list").forEach((list) => {
    const wrap = list.parentElement;
    const inp = $(".input input", wrap);
    if (!inp) return;
    const items = $$(".c-item", list);
    items.forEach((it) => {
      const span = $("span", it);
      if (span) span.dataset.raw = span.textContent;
    });
    inp.addEventListener("input", () => {
      const q = inp.value.trim().toLowerCase();
      items.forEach((it) => {
        const span = $("span", it);
        const raw = span ? span.dataset.raw : it.textContent;
        const i = raw.toLowerCase().indexOf(q);
        it.style.display = !q || i >= 0 ? "" : "none";
        if (span) span.innerHTML = q && i >= 0
          ? raw.slice(0, i) + "<mark>" + raw.slice(i, i + q.length) + "</mark>" + raw.slice(i + q.length)
          : raw;
      });
    });
    items.forEach((it) =>
      it.addEventListener("click", () => {
        items.forEach((x) => x.classList.remove("sel"));
        it.classList.add("sel");
        inp.value = ($("span", it)?.dataset.raw || it.textContent).trim();
      })
    );
  });

  /* ---- snackbar cancel ---- */
  $$(".snack").forEach((s) =>
    $(".btn", s)?.addEventListener("click", () => {
      s.style.transition = "all .28s";
      s.style.opacity = "0";
      s.style.transform = "translateY(10px)";
      setTimeout(() => (s.style.display = "none"), 280);
    })
  );

  /* ---- retry state: spins, then recovers ---- */
  $$(".retry .btn").forEach((b) =>
    b.addEventListener("click", () => {
      const card = b.closest(".retry");
      const ic = $(".r-ic", card), title = $("b", card);
      ic.style.animation = "spin .8s linear infinite";
      title.textContent = "Syncing…";
      b.disabled = true;
      setTimeout(() => {
        ic.style.animation = "";
        ic.textContent = "✓";
        ic.classList.remove("glass-red");
        ic.classList.add("glass-green");
        title.textContent = "All synced";
        $(".muted", card).textContent = "12 objects pushed to main";
        b.disabled = false;
      }, 1300);
    })
  );

  /* ---- voice / player wave toggle ---- */
  $$(".wave").forEach((w) => {
    const btn = w.parentElement?.querySelector("button");
    if (!btn || !btn.closest(".demo-body, .input, .glass-2")) return;
    w.classList.add("paused");
    btn.addEventListener("click", () => {
      const live = w.classList.toggle("paused") === false;
      if (btn.textContent.includes("●") || btn.textContent.includes("■"))
        btn.textContent = live ? "■ Stop" : "● Rec";
      else if (btn.textContent.trim().match(/^[▶▸⏸]/))
        btn.textContent = live ? "⏸" : "▶";
    });
  });

  /* ---- post / comment actions: like counts, share ---- */
  $$(".p-actions span").forEach((s) =>
    s.addEventListener("click", () => {
      const txt = s.textContent.trim();
      if (txt.startsWith("♥")) {
        const liked = s.classList.toggle("liked");
        const n = (+txt.replace(/\D/g, "") || 0) + (liked ? 1 : -1);
        s.textContent = "♥ " + n;
      } else if (txt.startsWith("↗")) {
        toast("info", "Link copied", "aurora.glass/p/402 — ready to share");
      }
    })
  );

  /* ---- follow buttons ---- */
  $$(".card .btn, .pop .btn").forEach((b) => {
    if (b.textContent.trim() !== "Follow") return;
    b.addEventListener("click", () => {
      const on = b.classList.toggle("on-follow");
      b.textContent = on ? "✓ Following" : "Follow";
      b.classList.toggle("btn-primary", !on);
    });
  });

  /* ---- auth sign-in busy state ---- */
  $$(".auth .btn-primary").forEach((b) =>
    b.addEventListener("click", () => {
      if (b.dataset.busy) return;
      b.dataset.busy = "1";
      const old = b.innerHTML;
      b.innerHTML = '<span class="conic-spin" style="width:14px;height:14px;display:inline-block;vertical-align:-2px"></span>';
      setTimeout(() => {
        b.innerHTML = "✓ Welcome back";
        toast("ok", "Signed in", "Session frosted for 30 days");
        setTimeout(() => { b.innerHTML = old; delete b.dataset.busy; }, 1500);
      }, 1100);
    })
  );

  /* ---- wizard: click a step to jump ---- */
  $$(".wizard").forEach((w) => {
    const steps = $$(".wstep", w);
    steps.forEach((s, i) =>
      s.addEventListener("click", () => {
        steps.forEach((x, j) => {
          x.classList.toggle("done", j < i);
          x.classList.toggle("now", j === i);
        });
        $$(".link", w).forEach((l, j) => l.classList.toggle("done", j < i));
      })
    );
  });

  /* ---- split button dropdown ---- */
  $$(".split .btn-more").forEach((b) => {
    const menu = document.createElement("div");
    menu.className = "menu glass-3 split-menu";
    menu.innerHTML = "<a>Merge & squash</a><a>Rebase & merge</a><a>Create patch</a>";
    b.parentElement.style.position = "relative";
    b.parentElement.appendChild(menu);
    b.addEventListener("click", (e) => {
      e.stopPropagation();
      menu.classList.toggle("open");
    });
    menu.addEventListener("click", (e) => {
      const a = e.target.closest("a");
      if (a) { menu.classList.remove("open"); toast("ok", a.textContent, "Queued on main"); }
    });
  });
  document.addEventListener("click", () =>
    $$(".split-menu.open").forEach((m) => m.classList.remove("open"))
  );

  /* ---- banner / empty-state CTAs ---- */
  $$(".inline-banner .btn").forEach((b) =>
    b.addEventListener("click", () => toast("ok", "Squircle shapes", "21 organic silhouettes — see Shapes"))
  );
  $$(".empty .btn").forEach((b) =>
    b.addEventListener("click", () => {
      b.textContent = "✓ Pane created";
      toast("ok", "Pane frosted", "New surface added to the stack");
      setTimeout(() => (b.textContent = "Create pane"), 1600);
    })
  );

  /* ---- progress bars + rings + sparkline animate into view ---- */
  const growIO = new IntersectionObserver((es) =>
    es.forEach((e) => {
      if (!e.isIntersecting) return;
      growIO.unobserve(e.target);
      const el = e.target;
      if (el.classList.contains("bar")) {
        const w = el.style.width;
        el.style.transition = "none";
        el.style.width = "0";
        requestAnimationFrame(() =>
          requestAnimationFrame(() => { el.style.transition = ""; el.style.width = w; })
        );
      } else if (el.matches(".val")) {
        const off = el.getAttribute("stroke-dashoffset");
        el.style.transition = "none";
        el.setAttribute("stroke-dashoffset", el.getAttribute("stroke-dasharray"));
        requestAnimationFrame(() =>
          requestAnimationFrame(() => { el.style.transition = ""; el.setAttribute("stroke-dashoffset", off); })
        );
      }
    }), { threshold: 0.5 });
  $$(".prog .bar").forEach((b) => growIO.observe(b));
  $$(".ring .val").forEach((c) => growIO.observe(c));

  /* ---- spark bars bounce on click ---- */
  $$(".spark .b").forEach((b) =>
    b.addEventListener("click", () => {
      b.style.transition = "transform .3s var(--spring)";
      b.style.transform = "scaleY(1.15)";
      setTimeout(() => (b.style.transform = ""), 300);
    })
  );

  /* ================================================================
     PER-COMPONENT SOURCE VIEWER — </> on every demo cell
     ================================================================ */
  const VOID = new Set(["input", "br", "img", "hr", "meta", "link", "circle", "path", "rect", "wbr", "span", "i", "b", "small"]);
  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const prettyHTML = (raw) => {
    const lines = raw.replace(/>\s*</g, ">\n<").split("\n");
    let depth = 0;
    return lines.map((ln) => {
      const t = ln.trim();
      const closing = /^<\//.test(t);
      if (closing) depth = Math.max(0, depth - 1);
      const out = "  ".repeat(depth) + t;
      const m = t.match(/^<([a-zA-Z][\w-]*)/);
      const opens = m && !closing && !/\/>$/.test(t) && !/<\//.test(t) && !VOID.has(m[1]);
      const selfClosedPair = /^<[^!][^>]*>.*<\/[^>]+>$/.test(t);
      if (opens && !selfClosedPair) depth++;
      return out;
    }).join("\n");
  };
  /* stash-aware highlighters: matches become "@@N@@" placeholders, restored
     at the end so later regexes can't match inside injected markup */
  const stashHL = (s, rules) => {
    const keep = [];
    let out = esc(s);
    rules.forEach(([re, fn]) => {
      out = out.replace(re, (m, ...g) => {
        keep.push(typeof fn === "string" ? `<span class="${fn}">${m}</span>` : fn(m, ...g));
        return "\x01" + (keep.length - 1) + "\x01";
      });
    });
    return out.replace(/\x01(\d+)\x01/g, (_, i) => keep[+i]);
  };
  const hlHTML = (s) => stashHL(s, [
    [/(&lt;!--[\s\S]*?--&gt;)/g, "tk-c"],
    [/([a-zA-Z-]+)=("[^"]*")/g, (m, n, v) => `<span class="tk-a">${n}</span>=<span class="tk-s">${v}</span>`],
    [/(&lt;\/?[a-zA-Z][\w-]*)/g, "tk-t"],
  ]);
  const hlCSS = (s) => stashHL(s, [
    [/(\/\*[\s\S]*?\*\/)/g, "tk-c"],
    [/([^{}\x01]+){/g, (m, sel) => `<span class="tk-t">${sel}</span>{`],
    [/([\w-]+)\s*:([^;{}\x01]*);/g, (m, p, v) => `<span class="tk-a">${p}</span>:<span class="tk-s">${v}</span>;`],
  ]);
  const hlJS = (s) => stashHL(s, [
    [/(\/\*[\s\S]*?\*\/|\/\/[^\n]*)/g, "tk-c"],
    [/(`[^`]*`|"[^"\n]*"|'[^'\n]*')/g, "tk-s"],
    [/\b(export|default|function|const|return|import|from|class|extends|static|new|this|final|required|void)\b/g, "tk-t"],
    [/\b([A-Z][\w.]*)\b/g, "tk-a"],
  ]);

  /* html -> react jsx: class->className, for->htmlFor, style="k:v"->style={{k:v}}, void self-close */
  const toJSX = (html) => {
    let s = html;
    s = s.replace(/class="/g, 'className="').replace(/for="/g, 'htmlFor="')
      .replace(/tabindex=/gi, "tabIndex=").replace(/stroke-width=/g, "strokeWidth=")
      .replace(/stroke-dasharray=/g, "strokeDasharray=").replace(/stroke-dashoffset=/g, "strokeDashoffset=")
      .replace(/stroke-linecap=/g, "strokeLinecap=").replace(/fill-rule=/g, "fillRule=")
      .replace(/clip-path=/g, "clipPath=").replace(/xlink:href=/g, "xlinkHref=")
      .replace(/onclick="[^"]*"/g, "").replace(/data-seg=""/g, "");
    s = s.replace(/style="([^"]*)"/g, (_, st) => "style={{ " + st.split(";").filter(Boolean).map((p) => {
      const i = p.indexOf(":");
      const k = p.slice(0, i).trim().replace(/-([a-z])/g, (m, c) => c.toUpperCase());
      return `${k}: "${p.slice(i + 1).trim()}"`;
    }).join(", ") + " }}");
    ["input", "br", "img", "hr", "meta", "link", "circle", "path", "rect", "wbr"].forEach((t) => {
      s = s.replace(new RegExp(`<${t}([^>]*[^/])>`, "g"), `<${t}$1 />`);
    });
    return s.replace(/^\s+/gm, (m) => m + "  ").split("\n").map((l) => "      " + l).join("\n");
  };

  const cssFor = (html) => {
    const cls = new Set();
    html.replace(/class="([^"]+)"/g, (_, c) => c.split(/\s+/).forEach((x) => x && cls.add(x)));
    const out = [];
    for (const sh of document.styleSheets) {
      if (!sh.href || !sh.href.includes("glass.css")) continue;
      for (const r of sh.cssRules) {
        const sel = r.selectorText || "";
        if (!sel) continue;
        if ([...cls].some((c) => new RegExp("\\." + c + "(?![\\w-])").test(sel))) out.push(r.cssText);
      }
    }
    return [...new Set(out)].join("\n\n");
  };

  /* tokens the snippet needs: :root vars + dark-theme overrides */
  let tokenCSS = "";
  for (const sh of document.styleSheets) {
    if (!sh.href || !sh.href.includes("glass.css")) continue;
    for (const r of sh.cssRules) {
      const sel = r.selectorText || "";
      if (sel === ":root" || sel === '[data-theme="dark"]' || sel === 'html[data-theme="dark"]') tokenCSS += r.cssText + "\n\n";
    }
  }
  tokenCSS = tokenCSS.trim();
  const sceneCSS = `/* paste-ready scene: dark colorful backdrop so the glass blur has something to melt */\nbody { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 40px; box-sizing: border-box; font-family: var(--font); color: var(--ink); background:\n    radial-gradient(60% 80% at 15% 20%, rgba(124,108,255,.35), transparent 60%),\n    radial-gradient(50% 70% at 85% 15%, rgba(84,217,255,.28), transparent 60%),\n    radial-gradient(70% 90% at 80% 85%, rgba(255,110,199,.25), transparent 60%),\n    var(--bg-0); }\n*{ box-sizing: border-box; }`;

  const pascal = (s) => s.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean).map((w) => w[0].toUpperCase() + w.slice(1)).join("") || "Component";

  const codex = $("#codex"), cxTitle = $("#cx-title"), cxNum = $("#cx-num"), cxCode = $("#cx-code");
  let cxBuf = { html: "", react: "", flutter: "" };
  const cxShow = (t) => {
    cxCode.innerHTML = t === "react" ? hlHTML(cxBuf.react)
      : t === "flutter" ? hlJS(cxBuf.flutter) : hlHTML(cxBuf.html);
  };
  $$("#cx-tabs button").forEach((b) =>
    b.addEventListener("click", () => {
      $$("#cx-tabs button").forEach((x) => x.classList.remove("on"));
      b.classList.add("on");
      cxShow(b.dataset.t);
    })
  );
  $("#cx-copy").addEventListener("click", () => {
    const t = $("#cx-tabs .on").dataset.t;
    navigator.clipboard?.writeText(cxBuf[t]);
    toast("ok", "Copied", `${$("#cx-tabs .on").textContent} source on your clipboard`);
  });

  $$(".demo").forEach((d) => {
    const num = $(".demo-num", d);
    if (!num) return;
    const btn = document.createElement("button");
    btn.className = "code-btn";
    btn.title = "View source";
    btn.innerHTML = "&lt;/&gt;";
    num.insertBefore(btn, $("i", num));
    btn.addEventListener("click", () => {
      const body = $(".demo-body", d).cloneNode(true);
      $$(".ripple, .split-menu, .code-btn", body).forEach((x) => x.remove());
      $$(".paused", body).forEach((x) => x.classList.remove("paused"));
      $$("[devin-hidden]", body).forEach((x) => x.removeAttribute("devin-hidden"));
      const html = prettyHTML(body.innerHTML.trim()).replace(/\s+devin-\w+="[^"]*"/g, "");
      const css = cssFor(html);
      const fullCSS = `${tokenCSS}\n\n${sceneCSS}\n\n${css}`.trim();
      const name = $("span", num).textContent;
      const comp = pascal(name);
      const cssBlock = `<style>\n${fullCSS}\n</style>\n\n`;
      const reactSrc =
        `/* ${comp} — Aurora Glass. Put this CSS in a stylesheet or a <style> tag:\n\n${fullCSS}\n\n*/\nexport default function ${comp}() {\n  return (\n    <>\n` +
        toJSX(html) +
        `\n    </>\n  );\n}`;
      const lvl = /glass-3/.test(html) ? "floating" : /glass-1/.test(html) ? "control" : "surface";
      const flutterSrc =
        `// ${comp} — Aurora Glass (flutter/glass_kit.dart)\n` +
        `// Mirror of the web demo below; GlassLevel.${lvl} matches the glass-${lvl === "control" ? "1" : lvl === "floating" ? "3" : "2"} used here.\n` +
        `GlassSurface(\n  level: GlassLevel.${lvl},\n  padding: const EdgeInsets.all(16),\n  child: /* rebuild this tree:\n\n` +
        html.split("\n").map((l) => `    ${l}`).join("\n") +
        `\n  */ const SizedBox.shrink(),\n)`;
      cxBuf = { html: cssBlock + html, react: reactSrc, flutter: flutterSrc };
      cxTitle.textContent = name;
      cxNum.textContent = $("i", num).textContent;
      $$("#cx-tabs button").forEach((x) => x.classList.toggle("on", x.dataset.t === "html"));
      cxShow("html");
      open("codex", true);
    });
  });

  /* ---- scroll progress bar ---- */
  const sprog = $("#scroll-progress");
  addEventListener("scroll", () => {
    const h = document.documentElement;
    sprog.style.width = (h.scrollTop / (h.scrollHeight - h.clientHeight) * 100) + "%";
  }, { passive: true });
})();

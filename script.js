const JSON_PATH = '../videos.json'
const SCALE = 0.15

let msnry = null
let items = []

console.log('script loaded')
document.addEventListener('DOMContentLoaded', init)

async function init() {
	const grid = document.getElementById('gallery')

	let data = null
	try {
		const res = await fetch(JSON_PATH, { cache: 'no-store' })
		data = await res.json()
		console.log('data: ', data)
	} catch (e) {
		console.error('videos.json 読込失敗:', e)
		data = { patterns: [], styles: [] }
	}

	// いま開いてるページで出し分け
	const isPatterns = location.pathname.includes('/patterns/')
	const list = isPatterns ? data.patterns || [] : data.styles || []

	items = list
		.filter((item) => item?.path?.toLowerCase().endsWith('.mp4'))
		.map((item) => {
			const src = item.path
			const jp = item.jp || ''
			const name = item.name || ''

			const fig = document.createElement('figure')

			// どっちの一覧ページかでリンク先を決める（ページ＝HTMLのパスを見てる）
			const isPatterns = location.pathname.includes('/patterns/')
			const href = isPatterns ? `./pattern_${name}.html` : `./style_${name}.html`

			// クリック領域をまるごとリンクにする
			const a = document.createElement('a')
			a.href = href
			a.className = 'card-link' // CSSで見た目調整用（任意）
			a.setAttribute('aria-label', `${jp || name} を開く`)

			const thumb = document.createElement('div')
			thumb.className = 'thumb'

			const v = document.createElement('video')
			v.autoplay = true
			v.loop = true
			v.muted = true
			v.playsInline = true
			v.preload = 'metadata'
			v.src = src

			thumb.appendChild(v)

			const cap = document.createElement('figcaption')
			cap.textContent = jp.trim() || src.split('/').pop()

			// a の中に入れる
			a.appendChild(thumb)
			a.appendChild(cap)

			fig.appendChild(a)
			grid.appendChild(fig)

			v.addEventListener(
				'loadedmetadata',
				() => {
					fig.dataset.intrinsicW = v.videoWidth || 0
					fig.dataset.intrinsicH = v.videoHeight || 0
				},
				{ once: true }
			)

			return fig
		})


	setUniformMode()
	// ... 以下トグルはそのまま
	// 4) トグル操作
	document.getElementById('btn-uniform').addEventListener('click', () => {
		setUniformMode()
		setActive('#btn-uniform')
	})
	document.getElementById('btn-waterfall').addEventListener('click', () => {
		setWaterfallMode()
		setActive('#btn-waterfall')
	})
}
document.addEventListener('DOMContentLoaded', () => {
	// index.html ではなく、個別動画ページだけで動かす
	const p = location.pathname
	const isVideoPage = /\/patterns\/pattern_.*\.html$/.test(p) || /\/styles\/style_.*\.html$/.test(p)

	if (!isVideoPage) return

	const titleText = document.title?.trim()
	if (!titleText) return

	// すでにタイトルが置かれてたら二重生成しない
	if (document.querySelector('[data-auto-page-title="1"]')) return

	const h = document.createElement('div')
	h.textContent = titleText
	h.setAttribute('data-auto-page-title', '1')

	// 見た目：小さめ、左上、読みやすく
	Object.assign(h.style, {
		position: 'fixed',
		top: '12px',
		left: '12px',
		zIndex: '9999',
		color: 'white',
		fontSize: '14px',
		fontFamily: 'system-ui, -apple-system, Segoe UI, Roboto, sans-serif',
		lineHeight: '1.2',
		padding: '6px 10px',
		background: 'rgba(0,0,0,0.45)',
		borderRadius: '10px',
		backdropFilter: 'blur(6px)',
		WebkitBackdropFilter: 'blur(6px)',
		userSelect: 'none',
		pointerEvents: 'none', // クリックを邪魔しない
	})

	document.body.appendChild(h)
})

function setActive(sel) {
	document.querySelectorAll('.view-toggle button').forEach((b) => b.classList.remove('active'))
	document.querySelector(sel).classList.add('active')
}
/* ===== モード1：格子 ===== */
function setUniformMode() {
	const grid = document.getElementById('gallery')
	// Masonry がいたら破棄
	if (msnry) {
		msnry.destroy()
		msnry = null
	}
	// クラス切替
	grid.classList.remove('mode-waterfall')
	grid.classList.add('mode-uniform')
	// 格子用に、カード幅はCSSで統一。videoは object-fit:cover（CSS側
	// ウォーターフォールで付与した inline-style をクリア
	items.forEach((fig) => {
		fig.style.width = ''
		// Masonry幅クリア
		fig.style.position = ''
		// 位置リセット（CSSが上書き）
	})
}
/* ===== モード2：ウォーターフォール ===== */
function setWaterfallMode() {
	const grid = document.getElementById('gallery')
	// クラス切替
	grid.classList.remove('mode-uniform')
	grid.classList.add('mode-waterfall')
	// 各動画カードの幅を「元の幅の15%」に設定（高さは自動）
	items.forEach((fig) => {
		const W = Number(fig.dataset.intrinsicW || 0)
		const H = Number(fig.dataset.intrinsicH || 0)
		if (W > 0 && H > 0) {
			// 幅だけ指定すれば、<video> は等比で高さが決まる（CSSで height:auto;）
			const scaledW = Math.max(80, Math.round(W * SCALE))
			// あまりに小さすぎるのを防ぐ下限80px
			fig.style.width = scaledW + 'px'
		} else {
			// まだ metadata 未取得なら仮幅
			fig.style.width = '200px'
		}
	}) // 画像/動画の読み込み完了に合わせてMasonry初期化
	// すでにあれば再レイアウト
	const doLayout = () => {
		if (!msnry) {
			msnry = new Masonry('#gallery', {
				itemSelector: 'figure',
				gutter: 12,
				percentPosition: false,
				// 可変幅アイテムを許容（columnWidth未指定 or 1でもOK）
			})
		} else {
			msnry.layout()
		}
	}
	// 一旦 layout、ロード進行でもレイアウト
	doLayout()
	imagesLoaded('#gallery').on('progress', doLayout)
	// 動画のmetadataが揃ってから最終レイアウト（幅が確定するため）
	document.querySelectorAll('#gallery video').forEach((v) => {
		v.addEventListener('loadedmetadata', doLayout, { once: true })
	})
	// リサイズ時も再レイアウト
	window.addEventListener('resize', () => msnry && msnry.layout(), { passive: true })
}

document.addEventListener('DOMContentLoaded', enhanceVideoPages)

function enhanceVideoPages() {
	// ギャラリー(index)ページには #gallery があるので除外
	const hasGallery = document.getElementById('gallery')
	if (hasGallery) return

	// 動画ページかどうか：video要素があるページだけ対象
	const video = document.querySelector('video')
	if (!video) return

	const pageTitle = (document.title || '').trim()
	if (!pageTitle) return

	// /patterns/ か /styles/ かで文言を切り替え
	const inPatterns = location.pathname.includes('/patterns/')
	const inStyles = location.pathname.includes('/styles/')

	// どっちでもなければ、とりあえず汎用ラベル
	const linkText = inPatterns ? '備え付け補助線パタン一覧へ' : inStyles ? '補助線スタイル一覧へ' : 'ギャラリーへ'

	// 同階層の index.html へ
	const indexHref = './index.html'

	// 既に挿入済みなら何もしない
	if (document.querySelector('.video-page-header')) return

	// ヘッダ生成
	const header = document.createElement('div')
	header.className = 'video-page-header'

	const h = document.createElement('div')
	h.className = 'video-page-title'
	h.textContent = pageTitle

	const a = document.createElement('a')
	a.className = 'video-page-backlink'
	a.href = indexHref
	a.textContent = linkText

	header.appendChild(h)
	header.appendChild(a)

	// body先頭に挿入（videoの上に出したいので）
	document.body.insertBefore(header, document.body.firstChild)

	// videoが全画面固定の場合でも見えるように、CSSクラスをbodyに付与
	document.body.classList.add('is-video-page')
}
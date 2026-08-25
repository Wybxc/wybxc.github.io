#import "/templates/post.typ": post
#import "/components/web.typ": *
#show: post.with(
  title: "A 2026 Survey of Rust GUI Libraries",
  pubDate: datetime(year: 2026, month: 8, day: 22),
)

= A 2026 Survey of Rust GUI Libraries

It has been more than one year since boringcactus's #link("https://www.boringcactus.com/2025/04/13/2025-survey-of-rust-gui-libraries.html")[A 2025 Survey of Rust GUI Libraries].
That was indeed a very interesting blog; so interesting that I wanted to try it myself.
So I will be testing and reviewing each of the libraries listed on the #link("https://areweguiyet.com")[Are We GUI Yet?] website.

The task I chose is a QR Code Generator. The interface has a text box; when text is entered, the Rust backend calculates the corresponding QR Code based on the text and displays it below the text box.

#center(invert(image("images/window.png", width: 25em)))

This task can cover many aspects that GUI frameworks need to consider. For example, the text box involves IME support, and displaying images from the backend tests the framework's compatibility with the existing Rust ecosystem.
In addition, this task is also a simplified version of a real example I encountered when I first used Rust to develop a GUI program this year.

Beyond basic feature completeness, I'll also give a fairly subjective usability rating, covering state management, styling, the complexity of scaffolding an initial project, and the editor experience.

To get a realistic feel, I'll try to hand-write each task as much as possible. Of course, in 2026, a major difference is the practical adoption of coding agents. If, during this survey, I come across a framework whose correct usage I can't figure out myself, but a coding agent can write the correct code on my behalf, then I'll still give that framework some credit for usability.

I'm on macOS, so the survey will be based on the macOS platform. For certain Windows-specific frameworks, I will also try running them in a Windows VM.

The #crossref(<conclusion>)[conclusion] and #crossref(<the-table>)[the table] are at the end of this article.

== Azul

When I opened Azul's #link("https://azul.rs")[homepage], I was greeted by a rather ambitious page introducing Azlin Workspace, Azlin UI Toolkit, and Azlin OS.
Although Azlin Workspace is basically a bunch of “Coming Soon” notices, and I'm not sure how Azlin relates to Azul, I still managed to get past the homepage and find the correct user documentation on GitHub.

It looks like Azul just released version 0.2.0, and according to the docs, I can simply install its runtime library via Homebrew.
Then, since Azul isn't published on crates.io, I had to clone its Git repo and run it to generate the Rust API bindings.

The first snag came right away: rust-analyzer didn't recognize the Rust code that Azul generated. It compiled and ran fine, but all editor hints for the relevant types were gone.

Well, that's not a huge deal; at least `cargo doc` is available. It's like going back to programming in the pre-LSP era.

After spending 10 minutes digging through the cargo docs and repeatedly invoking the compiler, I finally managed to stick a text box into its original example.
But then, no matter what I did, I couldn't get any text I typed into the box to actually show up.
So I asked Codex to help me debug this issue, and it turned out that Azul apparently couldn't read fonts installed on the system.
That alone is almost enough to rule out using Azul for this purpose. Not wanting to waste any more of my time (and tokens), I decided to move on to the next framework.

== Blinc

#link("https://project-blinc.github.io/Blinc")[Blinc] is a very new framework. It only released its first version in early 2026. Like many Rust GUI frameworks, Blinc uses wgpu as its rendering backend and adopts a reactive programming model. With rapid iteration, some examples in its official documentation are already outdated.

#image("images/gui-survey-2026/blinc.png", width: 30em)

The `TextInput` component feels unfinished: it doesn't let you set a font, and its reactive behavior requires manually triggering in the `on_change` event. Meanwhile, `TextArea` allows you to specify a signal as the target to trigger when it updates. However, I don't think either of these approaches really conforms to the reactive standard. True reactivity shouldn't require you to manually handle events or signals; it should directly propagate changes in input controls to wherever the state is used.

`TextInput`'s default font doesn't support CJK character display. IME works fine, but the composer position doesn't align with the text box position.

macOS's accessibility features don't work either; screen readers can't read out the content in the window.

#details(summary: "Full Code", fullwidth[
  ```rust
  use base64::Engine as _;
  use blinc_app::prelude::*;
  use blinc_app::windowed::{WindowedApp, WindowedContext};

  fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)?;
      Ok(buf)
  }

  fn main() -> Result<()> {
      tracing_subscriber::fmt()
          .with_max_level(tracing::Level::INFO)
          .init();

      let config = WindowConfig {
          title: "QRCode Generator".to_string(),
          width: 400,
          height: 400,
          resizable: false,
          ..Default::default()
      };

      WindowedApp::run(config, build_ui)
  }

  fn build_ui(ctx: &mut WindowedContext) -> impl ElementBuilder + use<> {
      let text = ctx.use_state_keyed("text", || {
          text_input_state_with_placeholder("https://example.com")
      });

      div()
          .w(ctx.width)
          .h(ctx.height)
          .padding(Length::Px(10.0))
          .flex_col()
          .bg_surface()
          .gap(24.0)
          .child(label("Enter text to generate QR code:").text_center())
          .child(text_input(&text.get()).on_change({
              let text = text.clone();
              move |_| text.update(|text| text)
          }))
          .child(stateful::<NoState>().deps([text.signal_id()]).on_state({
              let text = text.clone();
              move |_| {
                  let text = text.get().lock().unwrap().value.clone();
                  let img = qr_encode(&text).unwrap_or_else(|_| Vec::new());
                  let b64 = base64::engine::general_purpose::STANDARD.encode(&img);
                  div()
                      .w_full()
                      .flex_grow()
                      .flex_col()
                      .child(image(format!("data:image/png;base64,{b64}")).self_center())
              }
          }))
  }
  ```
])

== Cacao

#link("https://docs.rs/cacao/latest/cacao/")[Cacao] is a Rust binding for macOS AppKit. Honestly, I'd never tried this crate before. I expected it to be full of unspeakable unsafe things interacting with low-level Objective-C code. But after actually using it, I found its API surprisingly clean.

Cacao's recommended programming model is event-driven. Components in the inner layers can send events to the top level, where an event dispatcher modifies the state based on the information carried by the events. This is somewhat similar to the Elm architecture, but not as purely functional.

#image("images/gui-survey-2026/cacao.png", width: 30em)

Since it uses native macOS text input boxes, IME support is excellent.#strike[What surprised me, though, is that the screen reader didn't work properly. It seems some setting might need to be enabled, but I don't want to spend more effort digging through the docs to find it.] Screen reader also works properly.

#details(summary: "Full Code", fullwidth[
  ```rust
  use std::sync::Mutex;

  use cacao::appkit::window::{Window, WindowConfig, WindowDelegate};
  use cacao::appkit::{App, AppDelegate};
  use cacao::image::{Image, ImageView};
  use cacao::input::{TextField, TextFieldDelegate};
  use cacao::layout::{Layout, LayoutConstraint};
  use cacao::notification_center::Dispatcher;
  use cacao::text::Label;
  use cacao::view::View;

  fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)?;
      Ok(buf)
  }

  struct MyApp {
      window: Window<AppWindow>,
  }

  impl Default for MyApp {
      fn default() -> Self {
          let window = Window::with(WindowConfig::default(), AppWindow::default());
          Self { window }
      }
  }

  impl AppDelegate for MyApp {
      fn did_finish_launching(&self) {
          App::activate();

          self.window.set_minimum_content_size(400., 400.);
          self.window.show();
      }

      fn should_terminate_after_last_window_closed(&self) -> bool {
          true
      }
  }

  impl Dispatcher for MyApp {
      type Message = String;

      fn on_ui_message(&self, text: String) {
          let buf = qr_encode(&text).unwrap_or_else(|_| Vec::new());
          let image = Image::with_data(&buf);
          let window = self.window.delegate.as_ref().unwrap();
          window.image.lock().unwrap().replace(image);
          window
              .image_view
              .set_image(window.image.lock().unwrap().as_ref().unwrap());
      }
  }

  struct AppWindow {
      label: Label,
      input: TextField<MyInput>,
      image_view: ImageView,
      image: Mutex<Option<Image>>,
      content: View,
  }

  impl Default for AppWindow {
      fn default() -> Self {
          Self {
              label: Label::new(),
              input: TextField::with(MyInput),
              image_view: ImageView::new(),
              image: Mutex::new(None),
              content: View::new(),
          }
      }
  }

  impl WindowDelegate for AppWindow {
      const NAME: &'static str = "WindowDelegate";

      fn did_load(&mut self, window: Window) {
          window.set_title("QR Code Generator");
          window.set_minimum_content_size(300., 300.);

          self.label.set_text("Enter text to generate QR code:");
          self.content.add_subview(&self.label);
          self.content.add_subview(&self.input);
          self.content.add_subview(&self.image_view);
          window.set_content_view(&self.content);

          LayoutConstraint::activate(&[
              self.label
                  .center_x
                  .constraint_equal_to(&self.content.center_x),
              self.label
                  .top
                  .constraint_equal_to(&self.content.safe_layout_guide.top),
              self.label.width.constraint_equal_to_constant(280.),
              self.label.height.constraint_equal_to_constant(30.),
              self.input
                  .center_x
                  .constraint_equal_to(&self.content.safe_layout_guide.center_x),
              self.input
                  .top
                  .constraint_equal_to(&self.content.safe_layout_guide.top)
                  .offset(30.),
              self.input.width.constraint_equal_to_constant(280.),
              self.image_view
                  .center_x
                  .constraint_equal_to(&self.content.center_x),
              self.image_view
                  .top
                  .constraint_equal_to(&self.content.safe_layout_guide.top)
                  .offset(50.),
              self.image_view.width.constraint_equal_to_constant(200.),
              self.image_view.height.constraint_equal_to_constant(200.),
          ]);
      }
  }

  #[derive(Default)]
  struct MyInput;

  impl TextFieldDelegate for MyInput {
      const NAME: &'static str = "MyInput";

      fn text_did_change(&self, value: &str) {
          App::<MyApp, String>::dispatch_main(value.to_string());
      }
  }

  fn main() {
      App::new("com.hello.world", MyApp::default()).run();
  }
  ```
])

== Core-Foundation

Strictly speaking, #link("https://docs.rs/core-foundation/latest/core_foundation/")[Core Foundation] is not really a GUI library; it just provides some bindings to macOS system APIs. So I don't think it's reasonable for it to be listed on "Are We GUI Yet?". In the same repository, there is a `cocoa` crate that does provide bindings to the AppKit GUI library, but its underlying dependencies are outdated and it's very unidiomatic Rust#footnote[
  which is what I meant by "unspeakable unsafe things interacting with low-level Objective-C code"
], so I'll skip it for now.

== Crux

Boringcactus gave #link("https://redbadger.github.io/crux/")[Crux] a positive review in hir evaluation last year, but since ze said Crux only had mobile bindings and no desktop bindings, ze didn't actually test its functionality. Today, while checking the documentation, I found that Crux now has macOS bindings, so I decided to actually pull it out and compare it here.

I followed Crux's documentation to set up the project scaffold. Since Crux itself doesn't provide a GUI but rather an interface from the Rust core to various GUI shells, setting up the scaffold is slightly more complex than the previous projects, but still within a reasonable level of complexity. Once the setup was complete, it was easy to change the functionality from the Counter example to this survey's QR code generator.

#image("images/gui-survey-2026/crux.png", width: 25em)

On macOS, Crux uses SwiftUI for the interface. Since our evaluation criteria basically only look at the GUI side, it's a bit unfair to compare SwiftUI with other Rust GUI frameworks. SwiftUI's support for IME and screen readers is native and first-class.

#details(summary: "Full Code", fullwidth[
  Rust:
  ```rust
  use crux_core::bridge::{Bridge, EffectId};
  use crux_core::macros::effect;
  use crux_core::render::{RenderOperation, render};
  use crux_core::{App, Command, Core};
  use facet::Facet;
  use serde::{Deserialize, Serialize};

  fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)?;
      Ok(buf)
  }

  #[derive(Default)]
  pub struct Counter;

  impl App for Counter {
      type Event = Event;
      type Model = Model;
      type ViewModel = ViewModel;
      type Effect = Effect;

      fn update(&self, event: Event, model: &mut Model) -> Command<Effect, Event> {
          match event {
              Event::Update(text) => {
                  model.qr = qr_encode(&text).unwrap_or_default();
              }
          }

          render()
      }

      fn view(&self, model: &Model) -> ViewModel {
          ViewModel {
              qr: model.qr.clone(),
          }
      }
  }

  #[derive(Facet, Serialize, Deserialize, Clone, Debug)]
  #[repr(C)]
  pub enum Event {
      Update(String),
  }

  #[derive(Default)]
  pub struct Model {
      qr: Vec<u8>,
  }

  #[derive(Facet, Serialize, Deserialize, Clone, Default)]
  pub struct ViewModel {
      pub qr: Vec<u8>,
  }

  #[effect(facet_typegen)]
  #[derive(Debug)]
  pub enum Effect {
      Render(RenderOperation),
  }

  /// The main interface used by the shell
  pub struct CoreFfi {
      core: Bridge<Counter>,
  }

  impl Default for CoreFfi {
      fn default() -> Self {
          Self::new()
      }
  }

  #[boltffi::export]
  impl CoreFfi {
      #[must_use]
      pub fn new() -> Self {
          Self {
              core: Bridge::new(Core::new()),
          }
      }

      #[must_use]
      pub fn update(&self, data: &[u8]) -> Vec<u8> {
          let mut effects = Vec::new();
          match self.core.update(data, &mut effects) {
              Ok(()) => effects,
              Err(e) => panic!("{e}"),
          }
      }

      #[must_use]
      pub fn resolve(&self, id: u32, data: &[u8]) -> Vec<u8> {
          let mut effects = Vec::new();
          match self.core.resolve(EffectId(id), data, &mut effects) {
              Ok(()) => effects,
              Err(e) => panic!("{e}"),
          }
      }

      #[must_use]
      pub fn view(&self) -> Vec<u8> {
          let mut view_model = Vec::new();
          match self.core.view(&mut view_model) {
              Ok(()) => view_model,
              Err(e) => panic!("{e}"),
          }
      }
  }
  ```

  Swift:
  ```swift
  import App
  import SwiftUI
  import ImageIO

  struct ContentView: View {
      @ObservedObject var core: Core

      @State private var text: String = ""

      var body: some View {
          VStack(spacing: 16) {
              Text("Enter text to generate QR code:")

              TextField("input", text: $text)
                  .textFieldStyle(.roundedBorder)
                  .frame(maxWidth: 300)
                  .onChange(of: text) { _, newValue in
                      core.update(.update(newValue))
                  }

              if let qrImage {
                  qrImage
                      .resizable()
                      .interpolation(.none)
                      .scaledToFit()
                      .frame(width: 200, height: 200)
              } else {
                  Text("Enter some text to generate a QR code")
                      .foregroundColor(.secondary)
              }
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      private var qrImage: Image? {
          let data = Data(core.view.qr)
          guard !data.isEmpty,
                let source = CGImageSourceCreateWithData(data as CFData, nil),
                let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
          else { return nil }
          return Image(decorative: cgImage, scale: 1)
      }
  }

  #Preview {
      ContentView(core: Core())
  }
  ```
])

== Cushy

#link("https://docs.rs/cushy/latest/cushy/")[Cushy] doesn't seem to have changed much compared to a year ago. Even the comment in the README that doesn't match the actual code hasn't been fixed.

```rust
// Create a dynamic usize.
let count = Dynamic::new(0_isize);
```

The last release is still from 2024, so I'm a bit skeptical about whether retesting Cushy has any value. Still, let's give it a try; maybe things will be different on macOS compared to Windows.

Cushy's code is surprisingly concise to write. Maybe I was just intimidated by the complexity of the previous frameworks, but being able to finish the main core logic of the project in just a dozen or so lines made for a very enjoyable development experience. Cushy's API design is clean and intuitive, especially how a single `Dynamic` type expresses almost all the reactive features and can easily be converted between data and components.

Even more noteworthy is that Cushy is the first framework in this survey that integrates with the existing Rust ecosystem. It supports directly converting a `DynamicImage` from the `image` crate into a `Texture`, which saves a lot of intermediate conversion code.

#image("images/gui-survey-2026/cushy.png", width: 25em)

As for IME and screen reader support, the situation on macOS is similar to Windows. The intermediate results from the IME composer are not visible, but the final converter works fine#footnote[Check boringcactus's #link("https://www.boringcactus.com/2025/04/13/2025-survey-of-rust-gui-libraries.html#egui")[2025 survey] to learn what composer and converter in an IME are.], while the screen reader cannot recognize the content in the window.

#details(summary: "Full Code", fullwidth[
  ```rust
  use cushy::{
      Run,
      kludgine::{LazyTexture, wgpu::FilterMode},
      value::{Dynamic, Source},
      widget::{MakeWidget, WidgetInstance},
      widgets::{Image, input::InputValue},
  };

  fn qr_encode(text: &str) -> anyhow::Result<image::DynamicImage> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      Ok(image::DynamicImage::from(img))
  }

  fn main() -> cushy::Result {
      let text = Dynamic::new("".to_string());
      let qr = text.map_each(|text| {
          let img = qr_encode(text).unwrap_or_default();
          let texture = LazyTexture::from_image(img, FilterMode::Nearest);
          WidgetInstance::new(Image::new(texture))
      });
      let text_input = text.into_input();
      "Enter text to generate QR code:"
          .and(text_input)
          .and(qr)
          .into_rows()
          .into_window()
          .titled("QR Code Generator")
          .run()
  }
  ```
])

== CXX-Qt

Qt is indeed a framework that inspires both love and hate. On the one hand, Qt is almost inextricably tied to a language as intimidating as C++. But on the other hand, Qt's cross-platform compatibility is quite good. I have more than once built personal macOS versions of open-source software written with Qt.

For myself, I probably wouldn't choose to use Rust with Qt. But for the purpose of this survey, let's take a look at this Rust binding for Qt.

When it comes to anything C++-related, environment setup is always the biggest headache. I didn't want to spend time wrestling with Qt's environment configuration, so I just installed Qt via Nix. Then I tried running the #link("https://kdab.github.io/cxx-qt/book/")[CXX-Qt] example code -- oh, compile errors.

Because the error report was a jumble of errors from Rust, C++, and various other places, I decided to stop thinking and hand the problem over to Codex.

What surprised me, though not at all unexpectedly, was that this compile error was a double problem. I won't go into too much detail here; in short, the `qt-build-utils` used by CXX-Qt doesn't support the way Nix packages Qt, and cxx actually had a regression during a _patch_ version change (yet another SemVer joke). After an hour of discussion with the AI, I finally found a workaround to get it running. So let's give it a try.

#image("images/gui-survey-2026/cxx-qt.png", width: 25em)

Images can only be passed between Rust and Qt via data URLs, which I'm not very fond of. IME and screen reader both work fine#footnote[
  On macOS, there are actually two screen reader implementations: the more comprehensive VoiceOver, and "Speak items under the pointer." In CXX-Qt, only VoiceOver works properly; the second feature doesn't read window content. From here on, "screen reader" refers to VoiceOver by default.
].

#details(summary: "Full Code", fullwidth[
  Rust:
  ```rust
  use std::pin::Pin;

  use base64::Engine as _;
  use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QUrl};

  fn main() {
      let mut app = QGuiApplication::new();
      let mut engine = QQmlApplicationEngine::new();

      if let Some(engine) = engine.as_mut() {
          engine.load(&QUrl::from("qrc:/qt/qml/cc/wybxc/cxx_qt/demo/qml/main.qml"));
      }

      if let Some(app) = app.as_mut() {
          app.exec();
      }
  }

  fn qr_encode_data_url(text: &str) -> anyhow::Result<String> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code
          .render::<image::Luma<u8>>()
          .min_dimensions(256, 256)
          .build();

      let mut png = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut png), image::ImageFormat::Png)?;

      let b64 = base64::engine::general_purpose::STANDARD.encode(&png);
      Ok(format!("data:image/png;base64,{b64}"))
  }

  #[cxx_qt::bridge]
  pub mod qobject {
      unsafe extern "C++" {
          include!("cxx-qt-lib/qstring.h");
          type QString = cxx_qt_lib::QString;
      }

      extern "RustQt" {
          #[qobject]
          #[qml_element]
          #[qproperty(QString, text)]
          #[qproperty(QString, qr_code, cxx_name = "qrCode")]
          #[namespace = "my_object"]
          type MyObject = super::MyObjectRust;

          #[qinvokable]
          #[cxx_name = "generateQRCode"]
          fn generate_qr_code(self: Pin<&mut Self>);
      }
  }

  #[derive(Default)]
  pub struct MyObjectRust {
      text: cxx_qt_lib::QString,
      qr_code: cxx_qt_lib::QString,
  }

  impl qobject::MyObject {
      pub fn generate_qr_code(self: Pin<&mut Self>) {
          let text = self.text().to_string();
          let url = qr_encode_data_url(&text).unwrap_or_default();
          self.set_qr_code(cxx_qt_lib::QString::from(url.as_str()));
      }
  }
  ```

  QML:
  ```qml
  import QtQuick 2.12
  import QtQuick.Controls 2.12
  import QtQuick.Window 2.12

  import cc.wybxc.cxx_qt.demo 1.0

  ApplicationWindow {
      id: root
      height: 480
      title: qsTr("QR Code Generator")
      visible: true
      width: 640
      color: palette.window

      readonly property MyObject myObject: MyObject {
          onTextChanged: generateQRCode()
      }

      Column {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 10

          Label {
              text: qsTr("Enter text to generate QR code:")
              color: palette.text
          }

          TextField {
              id: inputField
              placeholderText: qsTr("https://example.com")
              onTextChanged: root.myObject.text = text
          }

          Image {
              id: qrCodeImage
              width: 256
              height: 256
              fillMode: Image.PreserveAspectFit
              source: root.myObject.qrCode
              visible: status === Image.Ready
          }
      }
  }
  ```
])

== Dioxus

#link("https://docs.rs/dioxus/latest/dioxus/")[Dioxus] is basically React in Rust. According to their description, on desktop they use the Wry framework to run a WebView and display the UI inside it, which is essentially what Tauri does.

Recently, Dioxus's development pace seems to have slowed down. There are reports that the team has shifted its focus to #link("https://github.com/DioxusLabs/blitz")[Blitz], a self-developed HTML/CSS rendering engine. The reason for this shift seems to be that AI agents nowadays need something that can render HTML more than they need a UI framework.

But regardless, this can be seen as a step for Dioxus to move away from WebView and toward a more native approach.

Incidentally, the niche of native rendering for Dioxus was originally occupied by Freya#footnote[We'll see it later.]. But now Freya has changed course, breaking away from Dioxus and adopting its own GUI model, so at the moment there isn't really a native-rendering Dioxus anymore#footnote[
  As noted in Reddit comments, Dioxus already includes experimental native rendering support (powered by Blitz) in version 0.7, with further improvements expected in the upcoming 0.8 release.
].

#image("images/gui-survey-2026/dioxus.png", width: 25em)

IME and screen reader both work fine.

#details(summary: "Full Code", fullwidth[
  ```rust
  use base64::Engine;
  use dioxus::prelude::*;

  fn main() {
      dioxus::launch(App);
  }

  fn qr_encode_data_url(text: &str) -> anyhow::Result<String> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();

      let mut png = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut png), image::ImageFormat::Png)?;

      let b64 = base64::engine::general_purpose::STANDARD.encode(&png);
      Ok(format!("data:image/png;base64,{b64}"))
  }

  #[component]
  fn App() -> Element {
      let mut text = use_signal(|| "".to_string());
      let qr = use_memo(move || qr_encode_data_url(&text()).unwrap_or_default());

      rsx! {
          document::Title { "QR Code Generator" }
          main {
              style: "display: flex; flex-direction: column",
              p { "Enter text to generate QR code:" }
              input {
                  r#type: "text",
                  placeholder: "Enter text here",
                  value: text,
                  oninput: move |evt| text.set(evt.value())
              }
              img {
                  src: "{qr}",
                  alt: "QR code"
              }
          }
      }
  }
  ```
])

== Dominator

#link("https://docs.rs/dominator/latest/dominator/")[Dominator] is a web-oriented framework, and its situation hasn't changed since 2025; it still doesn't natively provide desktop support.

== Egui

#link("https://docs.rs/egui/latest/egui/")[Egui] is a well-known immediate mode#footnote[If you're curious about what immediate mode is, check out #link("https://www.boringcactus.com/2025/04/13/2025-survey-of-rust-gui-libraries.html#egui")[boringcactus's 2025 survey].] GUI library in Rust. It supports multiple rendering backends, which allows it to be embedded in various game engines. Eframe is egui's desktop integration. Last year, eframe still used glow as the default rendering backend. In version 0.34 released this year, Eframe's default rendering backend has switched to egui-wgpu.
It seems wgpu is becoming the de facto standard for Rust graphics rendering, and the ecosystem is unifying, which is great to see.

#image("images/gui-survey-2026/egui.png", width: 25em)

Egui's default font doesn't support CJK characters; you need to manually add a CJK-capable font before they can be displayed. IME and the screen reader both work properly. In last year's article, Boringcactus mentioned that egui's IME support had some issues, but in my tests everything worked fine. This could be due to platform differences between Windows and macOS, or it could be that egui has genuinely improved its IME support over the past year.

Among GUI frameworks that use wgpu for rendering, egui is the first to offer good accessibility support, which is great.

#details(summary: "Full Code", fullwidth[
  ```rust
  use eframe::egui;
  use egui::{FontData, FontDefinitions, FontFamily};

  fn main() {
      let native_options = eframe::NativeOptions::default();
      eframe::run_native(
          "QR Code Generator",
          native_options,
          Box::new(|cc| Ok(Box::new(MyEguiApp::new(cc)))),
      )
      .unwrap();
  }

  struct MyEguiApp {
      text: String,
      qr: egui::TextureHandle,
  }

  impl MyEguiApp {
      fn new(cc: &eframe::CreationContext<'_>) -> Self {
          let mut db = fontdb::Database::new();
          db.load_system_fonts();
          let font = db
              .query(&fontdb::Query {
                  families: &[fontdb::Family::Name("Hiragino Sans GB")],
                  ..fontdb::Query::default()
              })
              .and_then(|id| {
                  db.with_face_data(id, |data, index| {
                      let mut font = FontData::from_owned(data.to_vec());
                      font.index = index;
                      font
                  })
              })
              .unwrap();
          let mut fonts = FontDefinitions::default();
          fonts.font_data.insert("cjk".into(), font.into());
          fonts
              .families
              .get_mut(&FontFamily::Proportional)
              .unwrap()
              .insert(0, "cjk".into());
          cc.egui_ctx.set_fonts(fonts);

          Self {
              text: String::new(),
              qr: cc.egui_ctx.load_texture(
                  "qr",
                  egui::ColorImage::from_gray([1, 1], &[255]),
                  egui::TextureOptions::default(),
              ),
          }
      }
  }

  impl eframe::App for MyEguiApp {
      fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
          egui::CentralPanel::default().show(ui, |ui| {
              ui.label("Enter text to generate QR code:");
              let resp = ui.add(egui::TextEdit::singleline(&mut self.text));
              if resp.changed()
                  && let Ok(code) = qrcode::QrCode::new(self.text.as_bytes())
              {
                  let img = code.render::<image::Luma<u8>>().build();
                  let size = [img.width() as usize, img.height() as usize];
                  self.qr.set(
                      egui::ColorImage::from_gray(size, img.as_raw()),
                      egui::TextureOptions::default(),
                  );
              }
              ui.image((self.qr.id(), self.qr.size_vec2()));
          });
      }
  }
  ```
])

== Floem

#link("https://docs.rs/floem/latest/floem/")[Floem] is the UI framework used by Lapce, a code editor written in Rust. As a code editor with a similar positioning, Lapce seems to have stagnated in development compared to the thriving Zed. The last commit in its repository was 4 months ago, and its last release was 7 months ago. As for Floem, its UI framework, it hasn't had a new release in nearly two years.

Floem's code is also quite concise to write, reminding me of Cushy earlier. Here as well, a single `RwSignal` type handles almost all reactive operations. In Floem, each component takes a closure that returns its display content. If you often deal with this kind of code in Rust, the moment you see a closure, you might feel a bit uneasy, because Rust's ergonomics for capturing closures are still not great. Although there has been some discussion in the community, there doesn't seem to be a stabilizable solution yet. But thank goodness, Floem's `RwSignal` type is actually `Copy`, which means I don't have to worry about how to copy it into each closure while writing code.

#image("images/gui-survey-2026/floem.png", width: 25em)

Unfortunately, IME doesn't work properly -- I can't even switch input methods inside the text box, and the screen reader also can't recognize the content in the window. Floem is regrettably poor in this regard. If the Lapce team has time to come back and take a look at their UI framework, maybe.

#details(summary: "Full Code", fullwidth[
  ```rust
  use floem::{Application, prelude::*, reactive::SignalRead, window::WindowConfig};

  fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)?;
      Ok(buf)
  }

  fn app() -> impl IntoView {
      let text = RwSignal::new(String::new());

      v_stack((
          label(|| "Enter text to generate QR code:"),
          text_input(text),
          img(move || qr_encode(&text.read().borrow()).unwrap_or_default()),
      ))
  }

  fn main() {
      Application::new()
          .window(
              |_| app(),
              Some(WindowConfig::default().title("QR Code Generator")),
          )
          .run();
  }
  ```
])

== FLTK

#quote[Rust bindings for the #link("https://docs.rs/fltk")[FLTK] 1.4 Graphical User Interface library.]

The name FLTK sounds like something from the same era as Tcl, and you get the feeling that its widgets would be full of that last‑century style.

So I looked up the history of FLTK, and sure enough, it was born in 1998. However, after nearly 30 years of evolution, it is still being updated to this day. The latest version is FLTK 1.4.5.

The Rust bindings for FLTK bundle the upstream source code, so I don't need to bother with environment setup.

Here I need to defend FLTK's layout system. Boringcactus said that FLTK has no concept of a widget's intrinsic size, but actually, as long as you place the widget inside a Flex layout, you can easily set its size; although it's not something you'd immediately think of. I checked FLTK's history, and at least by the time Boringcactus wrote that article, FLTK's Flex was already available.

Like all GUI frameworks from 20 years ago#footnote[It reminds me of my elementary school days, programming with Visual Basic and Delphi on Windows XP.], FLTK uses a callback-based programming model; back then, the concept of reactive didn't exist yet. One annoyance of using a callback-based model in Rust is the issue of component lifetimes. However, FLTK seems to handle this aspect quite well—at least for writing simple little programs like this, its approach to lifetimes is pretty intuitive.

#image("images/gui-survey-2026/fltk.png", width: 25em)

FLTK offers several default themes, but no matter which one you choose, they all look like they're straight out of 20 years ago.
IME works fine in the text box, and after enabling `fltk_accesskit`#footnote[Boringcactus once said integrating `fltk_accesskit` was difficult, but now it only takes two lines of code. They improved this in the 0.2 version released in September 2025.], the screen reader can also recognize the content in the window.

#details(summary: "Full Code", fullwidth[
  ```rust
  use ::image::{ImageFormat, Luma};
  use fltk::{prelude::*, *};
  use fltk_accesskit::{AccessibleApp, builder};

  fn qr_encode(text: &str) -> anyhow::Result<image::PngImage> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), ImageFormat::Png)?;
      Ok(image::PngImage::from_data(&buf)?)
  }

  fn main() {
      let app = app::App::default();
      let mut wind = window::Window::default()
          .with_size(300, 360)
          .with_label("QR Code Generator");
      let mut col = group::Flex::default_fill().column();
      let label = frame::Frame::default().with_label("Enter text to generate QR code:");
      let mut input = input::Input::default();
      let mut img = frame::Frame::default_fill();
      col.end();
      col.fixed(&label, 30);
      col.fixed(&input, 30);
      wind.end();

      input.set_trigger(enums::CallbackTrigger::Changed);
      input.set_callback(move |input| {
          img.set_image_scaled(Some(qr_encode(&input.value()).unwrap()));
          img.redraw();
      });

      wind.show();
      let ac = builder(wind).attach();
      app.run_with_accessibility(ac).unwrap();
  }
  ```
])

== Flutter Rust Bridge

#link("https://docs.rs/flutter_rust_bridge/latest/flutter_rust_bridge/")[Flutter Rust Bridge] is more of an FFI library between Rust and Flutter/Dart than a GUI library. From that perspective, it's probably a bit more similar to Crux mentioned above.

I've tried some development with Flutter before, but perhaps my projects weren't complex enough to need a Rust backend. I felt that keeping all the logic in Dart was actually sufficient. But since this library shows up on Are We GUI Yet?, let's give it a try and see what the development experience is like when embedding Rust into Flutter.

Before I start, though, I hope I haven't deleted the Flutter SDK from my computer. Setting it up from scratch every time is no easy task.

The Flutter Rust Bridge docs list over 6 ways to create a new project. Oh boy.

It seems Flutter now has a generic solution called "Native Assets" for integrating native backends, which, my intuition tells me, would save me the trouble of running code generators. Let's make things a bit more challenging for ourselves and go with it.

#image("images/gui-survey-2026/flutter_rust_bridge.png", width: 30em)

Well, as it turns out, Native Assets didn't save me from running code generators either. It seems like it just replaces the soon-to-be-deprecated cargokit. But Flutter developers are probably already used to running several code generators in watch mode in the background, so one more shouldn't be a big deal.

In Flutter Rust Bridge, there are two modes of interaction between Rust and Flutter. The first is to treat Rust as a library of functions: you define functions in Rust, then call them from Flutter. State management is still handled by Flutter. This mode aligns with the general expectation for a native library, where you only offload performance-critical parts to the native library. However, there is another mode where you can define UI state in Rust and completely take over Flutter's state management logic. In this case, Flutter is used purely as a DSL for defining GUI. That is to say, Flutter's native state management mechanisms like controller/state become completely unusable; you have to feed all state back to Rust via callbacks, and then Rust handles it. The reason Boringcactus encountered IME issues in hir test was that ze tried to use Flutter's controller in the second mode, which caused a new controller to be created on every render, leading to state conflicts.
The code below shows the second mode.

Since the interface is Flutter, basic IME and screen reader functionality work fine. One interesting thing is that Flutter adds some extra navigation information to the screen reader, such as which keys you can press to move focus to a certain position.

#details(summary: "Full Code", fullwidth[
  Rust:
  ```rust
  use flutter_rust_bridge::frb;

  #[frb(ui_state)]
  pub struct RustState {
      qr_code: Option<Vec<u8>>,
  }

  impl RustState {
      #[frb(sync)]
      pub fn new() -> Self {
          Self {
              qr_code: None,
              base_state: Default::default(),
          }
      }

      #[frb(ui_mutation)]
      pub fn set_text(&mut self, text: String) {
          self.qr_code = qr_encode(&text).ok();
      }

      #[frb(sync)]
      pub fn get_qr_code(&self) -> Option<Vec<u8>> {
          self.qr_code.clone()
      }
  }

  pub fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)?;
      Ok(buf)
  }
  ```
  Flutter:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:hello_flutter_rust_bridge/src/rust/api/simple.dart';
  import 'package:hello_flutter_rust_bridge/src/rust/frb_generated.dart';

  void main() => runRustApp(body: body, state: RustState.new);

  Widget body(RustState state) {
    final qrCode = state.getQrCode();
    return MaterialApp(
      title: "QR Code Generator",
      home: Scaffold(
        body: Column(
          children: [
            const Text("Enter text to generate QR code:"),
            TextField(onChanged: (value) => state.setText(text: value)),
            if (qrCode != null) Image.memory(qrCode, width: 200, height: 200),
          ],
        ),
      ),
    );
  }
  ```
])

== Freya

#link("https://docs.rs/freya/latest/freya/")[Freya] was once a framework I had high expectations for. It had the ambitious goal of bringing Dioxus to native desktop rendering. But later, Freya felt that Dioxus was limiting its design, so it pivoted to developing its own GUI interface. Let's try out the new Freya and see; hoping its developer interface is as easy to use as Dioxus.

#image("images/gui-survey-2026/freya.png", width: 25em)

Comparing the new Freya with the previous Dioxus example, it's clear that Freya's refactoring has simplified the code quite a bit. Dioxus's model is faithful to the Web DOM, and replicating that model on desktop doesn't actually bring any extra benefits.

Freya uses Skia as its rendering backend. In theory, I could create an image in Skia and hand it to Freya for rendering. But that's too much hassle. Freya provides a way to create images directly from RGBA pixels, which is probably a bit better than using data URLs.

IME works properly in Freya, but the screen reader cannot recognize the content.

#details(summary: "Full Code", fullwidth[
  ```rust
  use freya::{elements::image::ImageHandle, engine::prelude::*, prelude::*};

  fn main() {
      launch(LaunchConfig::new().with_window(WindowConfig::new(app).with_title("QR Code Generator")))
  }

  fn qr_encode(text: &str) -> Option<ImageHandle> {
      let code = qrcode::QrCode::new(text.as_bytes()).ok()?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::from(img).into_rgba8();

      Some(
          ImageHandle::from_rgba(
              img.width(),
              img.height(),
              img.into_raw().into(),
              AlphaType::Premul,
          )
          .unwrap(),
      )
  }

  fn app() -> impl IntoElement {
      let text = use_state(String::new);
      let qr = use_memo(move || qr_encode(&text.read()));

      rect()
          .width(Size::fill())
          .height(Size::fill())
          .padding(Gaps::new_all(12.))
          .children([
              label()
                  .text("Enter text to generate QR code:")
                  .into_element(),
              Input::new(text).into_element(),
          ])
          .children(
              qr.read()
                  .as_ref()
                  .map(|qr| image(qr.clone()).into_element()),
          )
  }
  ```
])

== Fui

#link("https://github.com/marek-g/rust-fui/blob/master/doc/SUMMARY.md")[Fui] is an MVVM-style GUI framework. Its API design struck me as a bit novel because it actually requires using async to create windows and run the application.

Combining GUI with async/await is a fascinating idea. But so far, I haven't seen any framework that really does this well.

Fui's README doesn't mention macOS support. I tried it and found that it indeed doesn't. Alright, let's move on to the next framework.

== Gemgui

#link("https://docs.rs/gemgui/latest/gemgui/")[Gemgui] seems a bit mysterious. Its description is just one sentence: "Graphics User Interface library."

After carefully reading the documentation, I found that gemgui is actually a framework written for Rust to integrate Web UIs. To make it seem comparable to other GUI frameworks, gemgui provides an option to run the Web UI using pywebview. This option requires you to download the pywebview library from PyPI. Using pywebview to pretend to be a native program is something I've done myself, but making a Rust program carry a Python runtime feels a bit top-heavy.

Although because it uses Web UI, its GUI score can't really be compared with other libraries, I'm still curious about what the development experience is like. Would developing a Web UI application with such a library be better than using a general web server like axum or poem?

#image("images/gui-survey-2026/gemgui.png", width: 30em)

The GUI development experience with gemgui is really intriguing: it almost brings a whole set of DOM operations into Rust. You can modify the DOM in Rust using equivalent operations, just as you would write DOM code in JS. For a project prototype, this is indeed a very convenient choice.
If I can overlook the unexpectedly inefficient implementations in gemgui (such as the way it handles images), I'd say it's a decent option for using WebUI in Rust.

#details(summary: "Full Code", fullwidth[
  Rust:
  ```rust
  use gemgui::graphics::bitmap::Bitmap;
  use gemgui::graphics::canvas::Canvas;
  use gemgui::graphics::color::rgb;
  use gemgui::ui::{Gui, Ui};
  use gemgui::{self, GemGuiError};

  include!(concat!(env!("OUT_DIR"), "/generated.rs"));

  pub fn qr_encode(text: &str) -> anyhow::Result<Bitmap> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let bitmap = img.iter().map(|&x| rgb(x, x, x)).collect::<Vec<_>>();
      Ok(Bitmap::from_bytes(img.width(), img.height(), bitmap))
  }

  #[tokio::main]
  async fn main() -> Result<(), GemGuiError> {
      let fm = gemgui::filemap_from(RESOURCES);
      let mut ui = Gui::new(fm, "hello.html", gemgui::next_free_port(30000u16)).unwrap();
      // use python ui
      ui.set_python_gui("QR Code Generator", 500, 600, &[], 0, None);
      ui.set_logging(true);

      let input = ui.element("textInput");
      input.subscribe_async("input", async |ui, ev| {
          let value = &ev.element().values().await.unwrap()["value"];
          if let Ok(qr) = qr_encode(value) {
              let canvas = Canvas::new(&ui.element("canvas"));
              canvas.draw_bitmap_at(0, 0, &qr);
          }
      });

      ui.run().await
  }
  ```

  HTML:
  ```html
  <!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta
        http-equiv="Cache-Control"
        content="no-cache, no-store, must-revalidate"
      />
      <meta http-equiv="Pragma" content="no-cache" />
      <meta http-equiv="Expires" content="0" />
      <title>Hello</title>
    </head>
    <body>
      <script type="text/javascript" src="gemgui.js"></script>
      <div style="display: flex; flex-direction: column; gap: 10px;">
        <p>Enter text to generate QR code:</p>
        <input type="text" id="textInput" placeholder="Enter text here" />
        <canvas id="canvas" width="300" height="300"></canvas>
      </div>
    </body>
  </html>
  ```
])

== GPUI

#link("https://www.gpui.rs/")[GPUI] is the UI framework that powers Zed. Lately, it feels like every so often I see someone on Reddit claiming they built some software's UI with GPUI. As the name suggests, GPU rendering is its selling point. So what's the user experience like as a UI framework? Let's give it a try.

As of 2026, GPUI still doesn't ship with a built-in text input component. I had to copy its 780-line text input example and build on top of it.

The first unfortunate thing was that the examples I copied from GitHub had clearly undergone API changes, so they wouldn't compile when used with the version of GPUI from crates.io. Moreover, GPUI's GitHub repository is located inside Zed's subtree, and their tags are organized according to Zed's version numbers, so I couldn't even figure out which Git commit corresponded to the version they published on crates.io.

The second was that I stared at this 700-line example for quite a while without being able to tell what programming model GPUI actually uses. It seems its other examples only have a static `Render`, so I couldn't find any clue as to how they manage state. At this point, it has exceeded the patience limit of a programmer in 2026, so I decided to hand the remaining work over to AI.

While the AI was still hard at work, I casually browsed through GPUI's examples to see what else was there. They actually have an example named `active_state_bug.rs`, whose main content demonstrates one of their bugs: `.active()` background gets stuck on every other click. Should I give them credit for their sense of humor?

Zed is an editor I really like, but it's hard to imagine that the user experience of GPUI, which powers it, could be this bad. Look at Lapce and Floem over there; although Lapce isn't as active as Zed nowadays, Floem as a UI framework is orders of magnitude better than GPUI.

#image("images/gui-survey-2026/gpui.png", width: 25em)

IME basically works, but the screen reader cannot access the content in the window. I say "basically" because while testing GPUI, I ran into an issue that none of the other UI frameworks had ever had: after typing a letter in the input method's composer, deleting it, and then typing again, an out-of-bounds array access occurs and the program panics and exits. Could this be why GPUI hasn't stabilized its text input as a built-in component because they themselves haven't fully tested whether text input has bugs?

GPUI also has another example that integrates AccessKit. Perhaps following that example would make the screen reader work properly in GPUI, but I've run out of patience to keep dealing with it.

#details(summary: "Full Code", fullwidth(
  web(
    raw(read("gpui.rs"), block: true, lang: "rust"),
    render: it => html.div(it, style: "max-height: 30em; overflow: auto"),
  ),
))

== GPUI Component

_Edit on 2026-08-23:_

After this blog post was published, there was considerable discussion in the community about #link("https://longbridge.github.io/gpui-component/")[GPUI Component]. Many said it could completely transform the GPUI development experience, and is the only proper way to use GPUI for non-Zed developers.
I therefore decided to add a section here to explore what using GPUI Component feels like.

#image("images/gui-survey-2026/gpui-component.png")

IME input works correctly, and screen readers are functional as well. However, to make text in the UI accessible to screen readers, I need to use GPUI's `text!` macro. If text is placed directly in the interface, or via the `Label` component from GPUI Component, that text will not be recognized by screen readers.

With the code simplifications enabled by GPUI Component, I can finally get a clear picture of how GPUI manages state. GPUI organizes the UI into a component tree and a render tree. The component tree is responsible for managing state and event subscriptions. Each time the view is redrawn, the component tree derives a render tree. This is somewhat reminiscent of React before functional components were introduced, but by leveraging Rust's RAII mechanism, GPUI can manage the lifecycle of the component tree more naturally.

I briefly looked through the GPUI Component codebase, and its repository size seems comparable to that of GPUI itself. Many thanks to the GPUI Component developers.

#details(summary: "Full Code", fullwidth[
  ```rust
  use gpui::*;
  use gpui_component::{
      Root, StyledExt,
      input::{Input, InputEvent, InputState},
  };
  use std::sync::Arc;

  pub fn qr_encode(text: &str) -> anyhow::Result<Arc<Image>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let mut buf = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut buf), image::ImageFormat::Png)?;
      Ok(Arc::new(Image::from_bytes(ImageFormat::Png, buf)))
  }

  pub struct HelloWorld {
      input: Entity<InputState>,
      qr: Option<Arc<Image>>,
      _subscription: Subscription,
  }

  impl HelloWorld {
      pub fn new(window: &mut Window, cx: &mut Context<Self>) -> Self {
          let input = cx.new(|cx| InputState::new(window, cx));
          let subscription = cx.subscribe_in(&input, window, |view, state, event, _, cx| {
              if let InputEvent::Change = event {
                  let text = state.read(cx).value();
                  view.qr = qr_encode(&text).ok();
              }
          });

          Self {
              input,
              qr: None,
              _subscription: subscription,
          }
      }
  }

  impl Render for HelloWorld {
      fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
          div()
              .v_flex()
              .gap_2()
              .child(text!("Enter text to generate QR code:"))
              .child(Input::new(&self.input))
              .child(if let Some(qr) = &self.qr {
                  img(qr.clone()).size_48().into_any_element()
              } else {
                  div().size_48().into_any_element()
              })
      }
  }

  fn main() {
      let app = gpui_platform::application().with_assets(gpui_component_assets::Assets);

      app.run(move |cx| {
          gpui_component::init(cx);

          cx.spawn(async move |cx| {
              cx.open_window(WindowOptions::default(), |window, cx| {
                  window.set_window_title("QR Code Generator");
                  let view = cx.new(|cx| HelloWorld::new(window, cx));
                  cx.new(|cx| Root::new(view, window, cx))
              })
              .expect("Failed to open window");
          })
          .detach();
      });
  }
  ```
])

== GTK 3

#quote[UNMAINTAINED Rust bindings for the #link("https://gtk-rs.org/gtk3-rs/stable/latest/docs/gtk/")[GTK+ 3] library (use gtk4 instead).]

That's what Are We GUI Yet? and crates.io say. But when I went and checked their GitHub repository, it had actually been updated as recently as yesterday (2026-08-18), and quite frequently at that. However, they indeed haven't released a new version in nearly three years or more. I'm a bit curious what's going on here, so why not give their GitHub version a try?

First off, there's a Rust version issue. The library was updated to the Rust 2024 edition in a commit from a few days ago, but a piece of code gated by `#[cfg(macos)]` still uses the old syntax, so it won't compile on the newer Rust compiler, while older compilers will reject it because the rest of the code has already been upgraded to the 2024 edition. Fortunately, pinning the version to a slightly earlier commit solves the problem.

I thought I would need to use Nix again to solve the native library dependencies. But then I found I had installed GTK via Homebrew at some point. Well, at least that saves me from having to fiddle with the environment any further.

#image("images/gui-survey-2026/gtk3.png", width: 25em)

IME doesn't work properly, and the screen reader can't recognize the window's content either.
I noticed that the GTK 3 repository has bindings for ATK (Accessibility Toolkit), but I couldn't find documentation on how to integrate ATK into GTK.

#details(summary: "Full Code", fullwidth[
  ```rust
  use gtk::gdk_pixbuf::{Colorspace, Pixbuf};
  use gtk::glib::Bytes;
  use gtk::prelude::*;
  use gtk::{Application, ApplicationWindow};

  fn main() {
      let app = Application::builder()
          .application_id("org.example.HelloWorld")
          .build();

      app.connect_activate(|app| {
          let win = ApplicationWindow::builder()
              .application(app)
              .title("QR Code Generator")
              .build();

          let b = gtk::Box::builder()
              .orientation(gtk::Orientation::Vertical)
              .spacing(6)
              .build();
          win.set_child(Some(&b));

          b.add(
              &gtk::Label::builder()
                  .label("Enter text to generate QR code:")
                  .build(),
          );

          let input = gtk::Entry::builder().build();
          b.add(&input);

          let img = gtk::Image::builder().build();
          b.add(&img);

          input.connect_changed(move |input| {
              let text = input.text();
              if let Ok(qr) = qr_encode(&text) {
                  img.set_from_pixbuf(Some(&qr));
              }
          });

          win.show_all();
      });

      app.run();
  }

  pub fn qr_encode(text: &str) -> anyhow::Result<Pixbuf> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).to_rgb8();
      let width = img.width();
      let height = img.height();
      Ok(Pixbuf::from_bytes(
          &Bytes::from_owned(img.into_raw()),
          Colorspace::Rgb,
          false,
          8,
          width as i32,
          height as i32,
          width as i32 * 3,
      ))
  }
  ```
])

== GTK 4

#link("https://gtk-rs.org/gtk4-rs/stable/latest/docs/gtk4")[GTK 4] overall feels quite similar to GTK 3. I was able to take the code I had in GTK 3, make a few small changes, and run it on GTK 4.

#image("images/gui-survey-2026/gtk4.png", width: 25em)

IME now works properly, which is an improvement over GTK 3. However, the screen reader still can't recognize the content in the window. The GTK documentation has plenty about accessibility, so why doesn't it actually work in practice?

Unlike on Windows, GTK on macOS doesn't use its client-side window decorations; instead, it opts for server-side decorations like other applications. At least that way it doesn't look so out of place.

#details(summary: "Full Code", fullwidth[
  ```rust
  use gtk4 as gtk;
  use gtk::glib::Bytes;
  use gtk::prelude::*;
  use gtk::{Application, ApplicationWindow};
  use gtk::gdk::{MemoryFormat, MemoryTexture};

  fn main() {
      let app = Application::builder()
          .application_id("org.example.HelloWorld")
          .build();

      app.connect_activate(|app| {
          let win = ApplicationWindow::builder()
              .application(app)
              .title("QR Code Generator")
              .build();

          let b = gtk::Box::builder()
              .orientation(gtk::Orientation::Vertical)
              .spacing(6)
              .build();
          win.set_child(Some(&b));

          b.append(
              &gtk::Label::builder()
                  .label("Enter text to generate QR code:")
                  .build(),
          );

          let input = gtk::Entry::builder().build();
          b.append(&input);

          let img = gtk::Picture::builder().width_request(200).height_request(200).build();
          b.append(&img);

          input.connect_changed(move |input| {
              let text = input.text();
              if let Ok(qr) = qr_encode(&text) {
                  img.set_paintable(Some(&qr));
              }
          });

          win.present();
      });

      app.run();
  }

  pub fn qr_encode(text: &str) -> anyhow::Result<MemoryTexture> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).to_rgb8();
      let width = img.width();
      let height = img.height();
      Ok(MemoryTexture::new(
          width as i32,
          height as i32,
          MemoryFormat::R8g8b8,
          &Bytes::from(&img.into_raw()),
          width as usize * 3,
      ))
  }
  ```
])

== Iced

#link("https://docs.rs/iced/latest/iced/")[Iced] is a GUI framework that uses the Elm Architecture as its model. The so-called Elm Architecture originates from the frontend framework Elm and is a way of writing GUIs using functional programming. It requires centralizing all program state in one place and treating it as the single source of truth. The program's interface can be determined by computing from the state, and GUI inputs are represented as transitions from the current state to a new state.
#footnote[
  If you want a more functional programming-style explanation, the Elm Architecture decomposes a GUI program into a reader monad and a state monad. Although this perspective does no help with writing programs.
]

In my personal experience, the Elm Architecture is beautiful in theory, but in practice it comes with many subtle points of friction. For example, in a sufficiently large GUI program, it's true that most state is meant to be globally available, and lifting it into a common model makes sense. But there is also plenty of state that is meant as internal detail, only used by a specific component. If you have to put all that state into the global state as well, the abstraction leak problem becomes quite severe.

I've rambled on enough. I haven't actually used iced before, so let's see how it works in practice.

#image("images/gui-survey-2026/iced.png", width: 25em)

IME works fine, but the screen reader cannot recognize the content in the window.

For a simple example like this, the Elm Architecture is still quite comfortable to use.

However, there's one small thing to nitpick about iced's widget DSL. Since they already use macros like `column!` when creating widget lists, they could go further and customize the syntax. For example, for dynamic widget creation scenarios, they could support Flutter-style insertion of `if` and `for` expressions directly in the list, like this:

```rust
column![
    text("Enter text to generate QR code:"),
    text_input("https://example.com", &state.text).on_input(Message::SetText),
    if let Some(qr) = &state.qr { image(qr.clone()) },
]
```

#quote(block: true)[
  _Edit 2026-08-23:_

  Reddit user throwing_in_silence pointed out that an `Option<impl Into<Element>>` can be used directly in a widget list, so the above code can be changed to the following realistic version:

  ```rust
  column![
      text("Enter text to generate QR code:"),
      text_input("https://example.com", &state.text).on_input(Message::SetText),
      state.qr.as_ref().map(|qr| image(qr.clone()))
  ]
  ```

  This simplifies the code, but how would a user know? They'd have to notice in the `Element` docs that `Element` implements `From<Option<T>>`, but someone writing an optional component is unlikely to look there. Even knowing the answer, I first checked `Widget` trait and found nothing, then the `column!` macro revealed it accepts `Into<Element>`, which led me to `Element`.

  This reminds me of something interesting I encountered later while exploring Xilem.
  Similarly in Xilem, I didn't realize `Option<T>` could go directly in the component list. My first attempt used a branch of two- and three-element versions, requiring type erasure to `AnyWidgetView` (`dyn AnyView`). The `AnyWidgetView` docs then noted that I can insert an `Option` into a `ViewSequence`.  This is surprising since there is no obvious connection between `AnyWidgetView` and `ViewSequence`. It's likely that someone hit this, discovered `Option`, and asked the author to add that note.
]

Another point is that iced's documentation discoverability is not great. Because many of its widgets (like `image`) are generic, and when creating them you need to pass a generic type parameter. You have to dig into the docs to find the default implementation of that generic to know how to construct that parameter.

#details(summary: "Full Code", fullwidth[
  ```rust
  use iced::Element;
  use iced::widget::{column, container, image, text, text_input};

  pub fn main() -> iced::Result {
      iced::application(State::default, update, view)
          .title(|_: &State| "QR Code Generator".to_string())
          .run()
  }

  #[derive(Debug, Default)]
  struct State {
      text: String,
      qr: Option<image::Handle>,
  }

  #[derive(Debug, Clone)]
  enum Message {
      SetText(String),
  }

  fn update(state: &mut State, message: Message) {
      match message {
          Message::SetText(text) => {
              state.text = text;
              state.qr = qr_encode(&state.text).ok();
          }
      }
  }

  fn view(state: &State) -> Element<'_, Message> {
      container({
          let children = column![
              text("Enter text to generate QR code:"),
              text_input("https://example.com", &state.text).on_input(Message::SetText),
          ]
          .spacing(10);
          if let Some(qr) = &state.qr {
              children.push(image(qr.clone()))
          } else {
              children
          }
      })
      .into()
  }

  pub fn qr_encode(text: &str) -> anyhow::Result<image::Handle> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<::image::Luma<u8>>().build();
      let (width, height) = img.dimensions();
      let pixels = ::image::DynamicImage::ImageLuma8(img)
          .into_rgba8()
          .into_raw();
      Ok(image::Handle::from_rgba(width, height, pixels))
  }
  ```
])

== Imgui

#link("https://docs.rs/imgui")[Imgui] is a Rust binding for Dear ImGui, a C++ immediate-mode GUI library. My main impression of Dear ImGui is its distinctive style: it always renders at a low resolution no matter what screen it's on.

Imgui doesn't seem very active. Its last release was two years ago, though the GitHub repo still sees occasional updates every month or two.

The main imgui repo doesn't have any complete examples; just a code snippet in the README. The README links to an imgui-examples repo that hasn't been updated in two years. I looked for the simplest example there, but all of them rely on a 100+ line shared file for window setup, and that file uses the glium backend, which is already marked deprecated in the main repo's README.

There's a newer `imgui-wgpu` backend available, but after digging through the repo and docs, it looks like I'd have to set up a wgpu context by hand. Ugh, modern graphics. My head already hurts.

Fortunately, I could build on the `imgui-wgpu` example. Although the example is full of boilerplate code for creating windows and managing the wgpu context, it was still fairly easy to modify.

#image("images/gui-survey-2026/imgui.png", width: 30em)

IME is not supported, and neither is the screen reader.

For comparison, I feel that imgui's API design is a bit cleaner than egui's. But at the same time, because imgui exposes a lot of details about the underlying renderer, it's not actually that clean in practice. Also, since imgui is a binding for a C++ library, in some places it has to follow conventions from the C++ ecosystem. For example, a text input can't accept a string containing `'\0'` (although I have no idea what keyboard could even produce such a string).

#details(summary: "Full Code", fullwidth(
  web(
    raw(read("imgui.rs"), block: true, lang: "rust"),
    render: it => html.div(it, style: "max-height: 30em; overflow: auto"),
  ),
))

== KAS

#link("https://docs.rs/kas/")[KAS] is a Rust GUI framework that pursues simplicity.

KAS's repository links to their tutorial and their blog. I really like open-source projects that maintain a blog, because the thought processes and the principles and rationale behind the project design recorded by the developers are often worth learning from, even for people who don't use the project. In KAS's blog, there is also a #link("https://kas-gui.github.io/blog/state-of-GUI-2022.html")[State of GUI 2022] that can be compared with the current state of things.

KAS's programming model falls somewhere between React's reactive model and the Elm Architecture. It allows attaching state to intermediate nodes in the component tree, where those nodes handle events and state updates from child components separately. Intuitively, this approach seems like it could solve the abstraction leak problem in the Elm Architecture. However, I can't say for sure how composable it actually is. Because it looks like they ran into some trouble composing stateful widgets, so they specifically designed a macro-based syntax for widget composing. Incidentally, this architecture design reminds me of Blinc's stateful components mentioned earlier, although I get the feeling the Blinc also hasn't fully figured out how to manage state in their programs.

#image("images/gui-survey-2026/kas.png", width: 25em)

IME and the screen reader both don't work properly. However, interestingly, in KAS's repository, I also saw tracking issues regarding IME and screen reader support. They both started in June 2025. Judging from the timing, it's quite likely they were influenced by the 2025 survey. Hopefully they'll keep up the momentum this year.

As expected, when trying to compose components with different states, KAS's API has a lot of friction. It reminds me of the days of playing with parser combinators. However, parser combinators generally provide a way to degrade types to `dyn Trait` to reduce type-system complexity. But for some reason, in KAS, they didn't choose to do this for widget types. This means when you want to create a series of widgets side by side, you have only two options: either use macros like `column!`, or hand-write a type to combine these components. The former is almost unusable for cross-component communication, because the local types generated by macros are completely opaque, making it impossible to get references to child components. The API for custom components also seems rough. For example, while writing this example, habits from other frameworks told me that I should feed the `TextEdited` event information back into the state, i.e., the controlled component mechanism from React. But it actually works without doing that. I don't quite understand why, but it runs, so let's just leave it at that.

#details(summary: "Full Code", fullwidth[
  ```rust
  use kas::{draw::ImageFormat, image::Sprite, prelude::*, widgets::*};

  #[derive(Clone, Debug)]
  struct TextEdited(String);

  fn qr_encode(text: &str) -> anyhow::Result<(Size, Vec<u8>)> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).into_rgba8();
      let size = Size::splat(img.width().cast());
      Ok((size, img.into_raw()))
  }

  #[impl_self]
  mod QrApp {
      #[widget]
      #[layout(column![self.label, self.input, self.sprite])]
      pub struct QrApp {
          core: widget_core!(),
          #[widget]
          label: adapt::Map<String, Label, fn(&String) -> &()>,
          #[widget]
          input: EditBox<edit::InstantParseGuard<String, String>>,
          #[widget]
          sprite: adapt::Map<String, Sprite, fn(&String) -> &()>,
      }

      impl Default for Self {
          fn default() -> Self {
              QrApp {
                  core: Default::default(),
                  label: Label::new("Enter text to generate a QR code:".into()).map(|_| &()),
                  sprite: Sprite::new().with_logical_size((256.0, 256.0)).map(|_| &()),
                  input: EditBox::instant_parser(|x: &String| x.into(), TextEdited),
              }
          }
      }

      impl Events for Self {
          type Data = String;

          fn handle_messages(&mut self, cx: &mut EventCx, _: &Self::Data) {
              if let Some(TextEdited(text)) = cx.try_pop()
                  && let Ok((size, data)) = qr_encode(&text)
              {
                  let draw = cx.draw_shared();
                  if let Ok(handle) = draw.image_alloc(ImageFormat::Rgba8, size)
                      && draw.image_upload(&handle, &data).is_ok()
                  {
                      self.sprite.set(cx, handle);
                  }
              }
          }
      }
  }

  fn main() -> kas::runner::Result<()> {
      env_logger::init();
      let window = Window::new(
          QrApp::default().with_state("https://example.com/".into()),
          "QR Code Generator",
      );
      kas::runner::Runner::new(())?.with(window).run()
  }
  ```
])

== Kittest

#link("https://docs.rs/kittest/latest/kittest/")[Kittest] is a UI automation testing framework based on AccessKit, and it currently provides egui integration. Clearly, it's not a framework for building GUIs, so let's move on to the next one.

== Leptos

#link("https://docs.rs/leptos/latest/leptos/")[Leptos] is a Rust framework for building full-stack web apps. On the UI side, it adopts a fine-grained reactive model.
Leptos doesn't provide a mode for packaging applications as desktop apps like Dioxus does; their focus is clearly more on the web domain.

== Lvgl

#link("https://docs.rs/lvgl/latest/lvgl/")[Lvgl] is a Rust binding for a GUI library developed for embedded devices. That's certainly a distinctive niche, and perhaps that alone is enough to make it stand out on Are We GUI Yet?. As far as I know, another GUI framework that can run in embedded environments is Slint. However, I don't have a usable embedded development board on hand, and this survey's scope is basically limited to desktop environments, so I can't pit them against each other in an embedded setting.

Lvgl can also run in desktop mode, simulating the peripherals of an embedded device. In that case, it uses SDL as the rendering backend. This mode sounds like it's mainly meant for developers to debug their programs before flashing them onto a board, so I find it hard to have high expectations for its performance as a desktop GUI.

The last release was three years ago. When I tried running the version on crates.io, it hit a segmentation fault. So I switched to the latest version on the main branch on GitHub, and after some painful environment setup, I finally got it running.

#image("images/gui-survey-2026/lvgl.png", width: 25em)

Given that embedded devices don't always have a keyboard, lvgl doesn't respond to keyboard events. You need to add a Keyboard widget and click on it to enter text. Well, that's certainly a refreshing experience. Of course, in this case there's no way to talk about IME support or accessibility.

Despite all this time, lvgl's Rust bindings still seem to be in an unfinished state. Many operations require getting raw pointers to widgets and going through the low-level lvgl-sys. For example, getting the text from a text box and setting the content of an image widget. Yes, that's the only way to make the image widget usable.

#details(summary: "Full Code", fullwidth[
  ```rust
  use std::thread::sleep;
  use std::time::{Duration, Instant};

  use cstr_core::{CStr, cstr};
  use embedded_graphics::pixelcolor::Rgb565;
  use embedded_graphics::prelude::*;
  use embedded_graphics_simulator::{
      OutputSettingsBuilder, SimulatorDisplay, SimulatorEvent, Window,
  };
  use lvgl::input_device::InputDriver;
  use lvgl::input_device::pointer::{Pointer, PointerInputData};
  use lvgl::widgets::{Img, Keyboard, Label, Textarea};
  use lvgl::{Align, Display, DrawBuffer, LvError, NativeObject, Widget};

  const HOR_RES: u32 = 240;
  const VER_RES: u32 = 360;
  const IMG_RES: u32 = 200;

  fn qr_encode(text: &str, buf: &mut [u8; (IMG_RES * IMG_RES * 2) as usize]) -> anyhow::Result<()> {
      let img: image::GrayImage = qrcode::QrCode::new(text.as_bytes())?
          .render::<image::Luma<u8>>()
          .max_dimensions(IMG_RES, IMG_RES)
          .quiet_zone(false)
          .build();
      for (x, y, pixel) in img.enumerate_pixels() {
          let c: u16 = if pixel.0[0] < 128 { 0x0000 } else { 0xFFFF }; // RGB565 black/white
          let i = ((y * IMG_RES + x) * 2) as usize;
          buf[i] = (c & 0xFF) as u8;
          buf[i + 1] = (c >> 8) as u8;
      }
      Ok(())
  }

  fn main() -> Result<(), LvError> {
      let mut sim_display: SimulatorDisplay<Rgb565> =
          SimulatorDisplay::new(Size::new(HOR_RES, VER_RES));

      let output_settings = OutputSettingsBuilder::new().scale(2).build();
      let mut window = Window::new("QR Code Generator", &output_settings);

      let buffer = DrawBuffer::<{ (HOR_RES * VER_RES) as usize }>::default();

      let display = Display::register(buffer, HOR_RES, VER_RES, |refresh| {
          sim_display.draw_iter(refresh.as_pixels()).unwrap();
      })?;

      // Define the initial state of your input
      let mut latest_touch_status = PointerInputData::Touch(Point::new(0, 0)).released().once();

      // Register a new input device that's capable of reading the current state of the input
      let _touch_screen = Pointer::register(|| latest_touch_status, &display)?;

      // Create screen and widgets
      let mut screen = display.get_scr_act()?;

      let mut label = Label::create(&mut screen)?;
      label.set_text(cstr!("Enter text to generate QR code:"));

      let mut text = Textarea::create(&mut screen)?;
      text.set_align(Align::TopMid, 0, 20);
      text.set_height(40);

      let mut img = Img::create(&mut screen)?;
      img.set_size(IMG_RES as i16, IMG_RES as i16);
      img.set_align(Align::TopMid, 0, 60);

      let mut buf = [255u8; (IMG_RES * IMG_RES * 2) as usize]; // RGB565
      let dsc = lvgl_sys::lv_img_dsc_t {
          header: {
              let mut h = lvgl_sys::lv_img_header_t::default();
              h.set_cf(lvgl_sys::LV_IMG_CF_TRUE_COLOR);
              h.set_w(IMG_RES);
              h.set_h(IMG_RES);
              h
          },
          data_size: buf.len() as u32,
          data: buf.as_ptr(),
      };

      let mut keyboard = Keyboard::create(&mut screen)?;
      keyboard.set_size(240, 120);
      keyboard.set_textarea(&mut text);

      text.on_event(|text, ev| {
          if let lvgl::Event::ValueChanged = ev {
              let text = unsafe {
                  let ptr = lvgl_sys::lv_textarea_get_text(text.raw().as_ptr());
                  CStr::from_ptr(ptr).to_string_lossy().into_owned()
              };
              if qr_encode(&text, &mut buf).is_ok() {
                  unsafe {
                      lvgl_sys::lv_img_set_src(
                          img.raw().as_mut(),
                          &dsc as *const _ as *const core::ffi::c_void,
                      )
                  };
              }
          }
      })?;

      'running: loop {
          let start = Instant::now();
          lvgl::task_handler();
          window.update(&sim_display);

          let events = window.events().peekable();

          for event in events {
              match event {
                  SimulatorEvent::MouseButtonDown {
                      mouse_btn: _,
                      point,
                  } => {
                      latest_touch_status = PointerInputData::Touch(point).pressed().once();
                  }
                  SimulatorEvent::MouseButtonUp {
                      mouse_btn: _,
                      point,
                  } => {
                      latest_touch_status = PointerInputData::Touch(point).released().once();
                  }
                  SimulatorEvent::Quit => break 'running,
                  _ => {}
              }
          }
          sleep(Duration::from_millis(5));
          lvgl::tick_inc(Instant::now().duration_since(start));
      }

      Ok(())
  }
  ```
])

== Makepad

#quote[#link("https://github.com/makepad/makepad")[Makepad] is an AI-accelerated application and game development environment for Rust.]

I remember a year ago they weren't saying that.

#quote[It also has a large set of AI backends integrated for embedding llms or generative AI models inside applications or run them easily on local hardware]

That doesn't sound like what a GUI framework should be doing.

Makepad's link on Are We GUI Yet? points to a placeholder crate; their real crate name seems to be `makepad-widgets`. But neither side has any documentation at all.
Let me just hope I have better luck with their examples.

The examples in the repository don't match the version published on crates.io. Moreover, it seems that Claude Code getting in on the act completely messed up their version management. Their git repository has two tags named `1.0.0` and `Last1.0`, and I can only infer from the dates which one corresponds to the version on crates.io.

#image("images/gui-survey-2026/makepad.png", width: 25em)

IME only partially works: it can receive text input, but it doesn't display the composer's content. The screen reader cannot recognize the content in the window.

It seems their carefully designed DSL is intended for some kind of live editor, yet in their repository, there's no documentation at all on how to install this editor.

#details(summary: "Full Code", fullwidth[
  ```rust
  use makepad_widgets::*;

  live_design! {
      use link::theme::*;
      use link::widgets::*;

      App = {{App}} {
          ui: <Root> {
              main_window = <Window> {
                  body = <View> {
                      flow: Down,
                      spacing: 30,
                      align: {x: 0.5, y: 0.5},
                      label = <Label> {
                          text: "Enter text to generate QR code:",
                      }
                      text_input = <TextInput> { }
                      image = <Image> { }
                  }
              }
          }
      }
  }

  app_main!(App);

  #[derive(Live, LiveHook)]
  pub struct App {
      #[live]
      ui: WidgetRef,
  }

  impl LiveRegister for App {
      fn live_register(cx: &mut Cx) {
          crate::makepad_widgets::live_design(cx);
      }
  }

  impl MatchEvent for App {
      fn handle_startup(&mut self, _cx: &mut Cx) {}

      fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
          let input = self.ui.text_input(id!(text_input));
          if let Some(text) = input.changed(actions) {
              let image = self.ui.image(id!(image));
              image
                  .load_png_from_data(cx, &qr_encode(&text).unwrap())
                  .unwrap();
          }
      }
  }

  impl AppMain for App {
      fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
          self.match_event(cx, event);
          self.ui.handle_event(cx, event, &mut Scope::empty());
      }
  }

  fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<::image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(
          &mut std::io::Cursor::new(&mut buf),
          ::image::ImageFormat::Png,
      )?;
      Ok(buf)
  }
  ```
])

== Masonry

#link("https://docs.rs/masonry/latest/masonry/")[Masonry] is a foundational framework for building GUI libraries in Rust.
Its goal is not to be a user-facing GUI framework, but rather to serve as a low-level framework for building GUI frameworks.
They provide a widget tree and the means to render it. Frameworks built on masonry are free to choose their state management model, such as immediate mode, the Elm Architecture, or reactive programming.
// Honestly, I have some doubts about this idea. Because many state management models are strongly tied to how components are organized. Once you've settled on a particular widget tree model, state management isn't something you can switch around freely.

Their documentation recommends users to use Xilem, a higher-level reactive GUI framework built on top of masonry.
We'll come back later to see what Xilem's usage looks like. For now, let's not follow their advice and instead see what it's like to use masonry directly by hand.

#image("images/gui-survey-2026/masonry.png", width: 25em)

Both IME and screen reader work fine. For a GUI framework with pure Rust and custom-rendered widgets, this is quite impressive. Among all the GUI libraries I've tested so far, only egui has reached this level.

Without any configuration, masonry's default font doesn't support rendering CJK characters. I initially thought it might be like egui, where system fonts aren't loaded, but after digging into it, I found that the issue is simply that its default font configuration doesn't include CJK fonts. As long as you specify an appropriate font name when constructing the widget, it will render properly.

Masonry's API feels very low-level indeed, but also very flexible. If the day ever comes when I need to build my own Rust GUI library (and if I actually do, I can't decide whether that's fortunate or unfortunate), masonry would be a good place to start; at least I'd get IME and accessibility support out of the box.

#details(summary: "Full Code", fullwidth[
  ```rust
  use masonry::core::{ErasedAction, NewWidget, Widget, WidgetId, WidgetTag};
  use masonry::parley::style::{FontStack, StyleProperty};
  use masonry::peniko::{ImageAlphaType, ImageData, ImageFormat};
  use masonry::properties::types::Length;
  use masonry::widgets::{Flex, Image, Label, Portal, TextAction, TextArea, TextInput};
  use masonry_winit::app::{AppDriver, DriverCtx, NewWindow, WindowId};
  use masonry_winit::winit::window::Window;

  const TEXT_INPUT_TAG: WidgetTag<TextInput> = WidgetTag::new("text-input");
  const LIST_TAG: WidgetTag<Flex> = WidgetTag::new("list");
  const WIDGET_SPACING: Length = Length::const_px(5.0);

  struct Driver {
      image_id: Option<WidgetId>,
  }

  impl AppDriver for Driver {
      fn on_action(
          &mut self,
          window_id: WindowId,
          ctx: &mut DriverCtx<'_, '_>,
          _widget_id: WidgetId,
          action: ErasedAction,
      ) {
          if action.is::<TextAction>() {
              let action = action.downcast::<TextAction>().unwrap();
              if let TextAction::Changed(new_text) = *action
                  && let Ok(qr) = qr_encode(&new_text)
              {
                  let render_root = ctx.render_root(window_id);
                  if let Some(image_id) = self.image_id {
                      render_root.edit_widget(image_id, |mut image| {
                          Image::set_image_data(&mut image.downcast(), qr);
                      })
                  } else {
                      render_root.edit_widget_with_tag(LIST_TAG, |mut list| {
                          let image = Image::new(qr).with_auto_id();
                          self.image_id = Some(image.id());
                          Flex::add_child(&mut list, image);
                      });
                  }
              }
          }
      }
  }

  pub fn make_widget_tree() -> NewWidget<impl Widget> {
      let label = NewWidget::new(Label::new("Enter text to generate QR code:"));
      let text_input = NewWidget::new_with_tag(
          TextInput::from_text_area(
              TextArea::new_editable("")
                  .with_style(StyleProperty::FontStack(FontStack::Source(
                      "system-ui, PingFang SC, Hiragino Sans GB, Microsoft YaHei, sans-serif".into(),
                  )))
                  .with_auto_id(),
          ),
          TEXT_INPUT_TAG,
      );

      let list = Flex::column()
          .with_child(label)
          .with_child(text_input)
          .with_spacer(WIDGET_SPACING);

      NewWidget::new(Portal::new(NewWidget::new_with_tag(list, LIST_TAG)))
  }

  fn qr_encode(text: &str) -> anyhow::Result<ImageData> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).into_rgba8();
      let (width, height) = img.dimensions();
      let data = img.into_raw();
      Ok(ImageData {
          data: data.into(),
          format: ImageFormat::Rgba8,
          alpha_type: ImageAlphaType::AlphaPremultiplied,
          width,
          height,
      })
  }

  fn main() {
      let window_attributes = Window::default_attributes()
          .with_title("QR Code Generator")
          .with_resizable(true);
      let driver = Driver { image_id: None };

      let event_loop = masonry_winit::app::EventLoop::with_user_event()
          .build()
          .unwrap();
      masonry_winit::app::run_with(
          event_loop,
          vec![NewWindow::new(
              window_attributes,
              make_widget_tree().erased(),
          )],
          driver,
          masonry::theme::default_property_set(),
      )
      .unwrap();
  }
  ```
])

== Maycoon

#quote[#link("https://crates.io/crates/maycoon")[Maycoon] is shutting down!]

A few months ago, the author of Maycoon announced that Maycoon had been deprecated and deleted its GitHub repository. According to the author, "Rust simply is not a good fit to make a UI framework." Let's take a moment of silence for Maycoon, then move on to the next framework.

== Pane UI

#link("https://docs.rs/pane_ui")[Pane UI] is a GUI framework that defines UIs in RON, renders them with wgpu, and supports hot reloading.

It does not adopt a reactive design; the RON data files used to define the UI are completely static. If you want to create dynamic content, you need to modify the UI through code at runtime. This is not really a bad idea, because before reactive programming was invented, this is how everyone did it, for example, Win32 UI and VCL.
// I would say that before many frameworks that claim to be reactive have even figured out what reactive actually means, choosing a traditional model like Pane UI is a prudent approach.

// Pane UI's layout system is also very similar to Win32 UI. The top level of its window is called root. At this level there is no concept of layout; all components are placed in a component list by types, and their positions are determined by their XY coordinates. For container components such as `ScrollPane` and `Tab`, they have a list of child components. The components in this list are arranged in order according to the direction specified by the parent component.

// However, Pane UI does not provide a declarative mechanism like Win32 UI for linking the size of a component to the window size. Instead, they set the center of the window as the coordinate origin and specify that the window height is 1080 logical pixels. This is indeed a rather clever approach, but for real-world UIs, it may seem somewhat inflexible.

Regarding the schema of the RON used to define UIs, Pane UI's README contains a somewhat incomplete description, which alone is not enough to understand how components are defined. However, one can infer what the schema should look like from the Rust documentation of the module they use to parse RON, although even then the information is still not complete.

Unfortunately, Pane UI cannot accomplish this task, because it does not support creating and inserting images at runtime. Neither attempting to modify the properties of an existing image nor creating a new image component is supported in Pane UI.
Perhaps there is also a hacky workaround: leveraging Pane UI's hot reload mechanism to modify the RON file used to load the UI at runtime. But that sounds a bit too crazy.

== Pax

#link("https://www.pax.dev")[Pax] is a GUI framework that emphasizes "designability", combining a Figma-like designer with the program's GUI. This sounds like a great idea, if it can actually work.

Pax's desktop support is macOS only, and it is still in alpha. In my attempt, its macOS version failed to compile due to an internal parameter mismatch error. Given that Pax has not been updated for two years, I decided not to waste any more time on it.

== Ply

#link("https://plyx.iz.rs/docs/getting-started/")[Ply] is also a newcomer to the Rust GUI framework scene this year. Its author published a #link("https://plyx.iz.rs/blog/introducing-ply/")[post] on the Are We GUI Yet? blog list titled "building apps in Rust shouldn't be this hard". That's certainly a good way to draw attention to a new project.

#image("images/gui-survey-2026/ply.png", width: 25em)

IME does not work properly. After adding some additional code to set up accessibility, the screen reader can read the contents of the window.

In the blog post, the author talks about the pain points they encountered with other Rust GUI frameworks and then introduces ply's builder-based API design. In practice, the code does feel more concise, and it plays well with editor autocompletion.

However, ply is not perfect in its API design. It adopts an immediate mode programming model, but the way it handles text box updates is through callbacks, which is somewhat problematic. To access external state inside the callback, I had to wrap it in `Rc<RefCell<T>>`, because the callback may outlive the GUI builder. But from the perspective of the actual GUI lifecycle, this extra wrapping is unnecessary, since an immediate mode GUI's lifetime is entirely confined to the rendering loop, and variables outside the loop should be freely accessible.

In addition, ply makes some odd choices for default values. For example, if you do not specify both `font_size` and `color` for your text, it will not display at all. I checked their documentation and found that the default `font_size` is 0 and the default color is transparent, which is very counterintuitive. The default `width` and `height` of an element also appear to be 0, which is equally unintuitive.

Overall, ply is probably still a ways away from the goal it claims of "shouldn't be this hard."

#details(summary: "Full Code", fullwidth[
  ```rust
  use ply_engine::prelude::*;
  use std::cell::RefCell;
  use std::rc::Rc;

  fn window_conf() -> macroquad::conf::Conf {
      macroquad::conf::Conf {
          miniquad_conf: miniquad::conf::Conf {
              window_title: "QR Code Generator".to_owned(),
              window_width: 800,
              window_height: 600,
              high_dpi: true,
              sample_count: 4,
              ..Default::default()
          },
          ..Default::default()
      }
  }

  fn qr_encode(text: &str) -> anyhow::Result<Texture2D> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).into_rgba8();
      Ok(Texture2D::from_rgba8(
          img.width() as u16,
          img.height() as u16,
          img.as_raw(),
      ))
  }

  #[macroquad::main(window_conf)]
  async fn main() {
      static DEFAULT_FONT: FontAsset = FontAsset::Path("assets/fonts/noto_sans_sc.ttf");
      let mut ply = Ply::<()>::new(&DEFAULT_FONT).await;

      let img: Rc<RefCell<Option<Texture2D>>> = Rc::new(RefCell::new(None));

      loop {
          clear_background(BLACK);

          let mut ui = ply.begin();

          ui.element()
              .width(grow!())
              .height(grow!())
              .layout(|l| {
                  l.direction(TopToBottom)
                      .gap(16)
                      .padding(12)
                      .align(CenterX, CenterY)
              })
              .children(|ui| {
                  ui.text("Enter text to generate QR code:", |t| {
                      t.font_size(12).color(WHITE).accessible()
                  });
                  ui.element()
                      .width(grow!())
                      .height(fit!(20.0))
                      .background_color(0x262220)
                      .corner_radius(6.0)
                      .text_input(|t| {
                          t.font_size(18).on_changed({
                              let img = img.clone();
                              move |text| *img.borrow_mut() = qr_encode(text).ok()
                          })
                      })
                      .accessibility(|a| a.role(AccessibilityRole::TextInput).label("input"))
                      .empty();
                  if let Some(img) = img.borrow().as_ref() {
                      ui.element()
                          .width(fixed!(200.0))
                          .height(fixed!(200.0))
                          .image(img.clone())
                          .empty();
                  }
              });

          ui.show(|_| {}).await;

          next_frame().await;
      }
  }
  ```
])

== QMetaObject

#link("https://docs.rs/qmetaobject/latest/qmetaobject/")[QMetaObject] is another Rust binding for Qt. Compared with CXX-Qt, this library is somewhat less active, and its documentation is relatively insufficient. It uses a more customized macro approach to create subclasses of QObject in Rust and allows them to be used in QML. In this simple example, the experience in terms of complexity is roughly similar to CXX-Qt.

Since the UI is built entirely with Qt, the final result is identical to the CXX-Qt one, so there is no need to show screenshots here.

#details(summary: "Full Code", fullwidth[
  ```rust
  use base64::Engine as _;
  use cstr::cstr;
  use qmetaobject::prelude::*;

  #[derive(QObject, Default)]
  struct MyObject {
      base: qt_base_class!(trait QObject),
      text: qt_property!(QString; WRITE set_text),
      qr_code: qt_property!(QString; NOTIFY qr_code_changed),
      qr_code_changed: qt_signal!(),
  }

  impl MyObject {
      fn set_text(&mut self, text: QString) {
          self.text = text;
          let code = qrcode::QrCode::new(self.text.to_string().as_bytes()).unwrap();
          let img = code.render::<image::Luma<u8>>().min_dimensions(256, 256).build();
          let mut png = Vec::new();
          img.write_to(&mut std::io::Cursor::new(&mut png), image::ImageFormat::Png).unwrap();
          let url = format!("data:image/png;base64,{}", base64::engine::general_purpose::STANDARD.encode(&png));
          self.qr_code = url.into();
          self.qr_code_changed();
      }
  }

  fn main() {
      qml_register_type::<MyObject>(cstr!("MyObject"), 1, 0, cstr!("MyObject"));
      let mut engine = QmlEngine::new();
      engine.load_data(r#"
          import QtQuick 2.12
          import QtQuick.Controls 2.12
          import QtQuick.Window 2.12
          import MyObject 1.0

          ApplicationWindow {
              id: root
              height: 480
              title: qsTr("QR Code Generator")
              visible: true
              width: 640
              color: palette.window

              readonly property MyObject myObject: MyObject {}

              Column {
                  anchors.fill: parent
                  anchors.margins: 10
                  spacing: 10

                  Label {
                      text: qsTr("Enter text to generate QR code:")
                      color: palette.text
                  }

                  TextField {
                      placeholderText: qsTr("https://example.com")
                      onTextChanged: root.myObject.text = text
                  }

                  Image {
                      width: 256
                      height: 256
                      fillMode: Image.PreserveAspectFit
                      source: root.myObject.qr_code
                      visible: status === Image.Ready
                  }
              }
          }
      "#.into());
      engine.exec();
  }
  ```
])

== Relm

#link("https://docs.rs/relm/")[Relm] is a GUI framework based on GTK that uses the Elm Architecture as its programming model.

Relm uses GTK 3, which is said to be deprecated. But as I found in my earlier investigation, the GTK 3 library is still being quietly updated, and relm itself is also being quietly updated. It released a new version this year, upgrading to Rust 2024 Edition, but there were no significant changes in functionality.

Since the UI part is essentially GTK, there is no need to include screenshots for comparison again.

#details(summary: "Full Code", fullwidth[
  ```rust
  use gtk::gdk_pixbuf::{Colorspace, Pixbuf};
  use gtk::glib::Bytes;
  use gtk::prelude::*;
  use relm::Widget;
  use relm_derive::{Msg, widget};

  #[derive(Msg)]
  pub enum Msg {
      Input(String),
      Quit,
  }

  #[widget]
  impl Widget for Win {
      fn model() {}

      fn update(&mut self, event: Msg) {
          match event {
              Msg::Input(text) => {
                  if let Ok(qr) = qr_encode(&text) {
                      self.widgets.img.set_from_pixbuf(Some(&qr));
                  }
              }
              Msg::Quit => gtk::main_quit(),
          }
      }

      view! {
          gtk::Window {
              title: "QR Code Generator",
              gtk::Box {
                  orientation: gtk::Orientation::Vertical,
                  spacing: 6,
                  gtk::Label {
                      label: "Enter text to generate QR code:"
                  },
                  gtk::Entry {
                      changed(text) => Msg::Input(text.text().to_string())
                  },
                  #[name="img"]
                  gtk::Image {},
              },
              delete_event(_, _) => (Msg::Quit, gtk::glib::Propagation::Proceed),
          }
      }
  }

  fn qr_encode(text: &str) -> anyhow::Result<Pixbuf> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).to_rgb8();
      let (w, h) = img.dimensions();
      Ok(Pixbuf::from_bytes(
          &Bytes::from_owned(img.into_raw()),
          Colorspace::Rgb,
          false,
          8,
          w as i32,
          h as i32,
          w as i32 * 3,
      ))
  }

  fn main() {
      Win::run(()).expect("Win::run failed");
  }
  ```
])

== Relm4

#link("https://docs.rs/relm4/")[Relm4] is the GTK 4 version of Relm. Apart from that, there doesn't seem to be much to say. Developing applications with it is just as enjoyable as with Relm.

#details(summary: "Full Code", fullwidth[
  ```rust
  use relm4::gtk::gdk::{MemoryFormat, MemoryTexture};
  use relm4::gtk::glib::Bytes;
  use relm4::gtk::prelude::*;
  use relm4::prelude::*;

  struct App {
      img: Option<MemoryTexture>,
  }

  #[derive(Debug)]
  enum Msg {
      Input(String),
  }

  #[relm4::component]
  impl SimpleComponent for App {
      type Init = ();
      type Input = Msg;
      type Output = ();

      view! {
          gtk::Window {
              set_title: Some("QR Code Generator"),
              gtk::Box {
                  set_orientation: gtk::Orientation::Vertical,
                  set_spacing: 6,
                  gtk::Label {
                      set_label: "Enter text to generate QR code:"
                  },
                  gtk::Entry {
                      connect_changed[sender] => move |e| sender.input(Msg::Input(e.text().to_string())),
                  },
                  gtk::Picture {
                      set_width_request: 200,
                      set_height_request: 200,
                      #[watch]
                      set_paintable: model.img.as_ref(),
                  },
              },
          }
      }

      fn init(_: (), root: Self::Root, sender: ComponentSender<Self>) -> ComponentParts<Self> {
          let model = App { img: None };
          let widgets = view_output!();
          ComponentParts { model, widgets }
      }

      fn update(&mut self, msg: Msg, _sender: ComponentSender<Self>) {
          let Msg::Input(text) = msg;
          self.img = qr_encode(&text).ok();
      }
  }

  fn qr_encode(text: &str) -> anyhow::Result<MemoryTexture> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Luma<u8>>().build();
      let img = image::DynamicImage::ImageLuma8(img).to_rgb8();
      let (w, h) = img.dimensions();
      Ok(MemoryTexture::new(
          w as i32,
          h as i32,
          MemoryFormat::R8g8b8,
          &Bytes::from(&img.into_raw()),
          w as usize * 3,
      ))
  }

  fn main() {
      RelmApp::new("org.example.HelloWorld").run::<App>(());
  }
  ```
])

== Ribir

#link("https://ribir.org/docs/introduction")[Ribir] is a reactive Rust GUI framework that claims to adopt a "non-intrusive declarative programming model." By this they mean you can first develop the data model for your application, and then adapt the UI to it. In this process, you do not need to make any modifications to the already designed data model. Although I really don't understand why this would actually be a problem, I feel that any well-designed GUI framework should be able to do this.
// Perhaps they think MVVM is too cumbersome, but in reality not that many frameworks actually adopt the MVVM model.

Since Ribir released version 0.3 in 2024, over the past two years it has prepared more than 60 alpha versions for 0.4. I don't know what exactly has allowed the developers to hold off for such a long time, but it has also piqued my interest in its new version somewhat.

After briefly looking through its documentation, I found that Ribir uses rather obscure notation in its macro syntax. Without the help of AI, I would never have figured out that to insert an optional image into the component tree, I should use syntax like this:

```rust
@ { pipe!($read(image).clone()) }
```

Its documentation spends a great deal of space explaining how this macro syntax works, but it doesn't say a word about why it was designed this way.

Ribir's documentation appears to be inconsistent with its implementation in some places. For example, the documentation for `Input` mentions that it emits a `TextChangedEvent`. However, this event does not actually exist; instead, text input changes should be handled in the `on_chars` event.
The documentation for the `Image` component says it accepts WebP format images, but in reality it is even more restrictive: it can only accept WebP images with RGBA pixels. If images with other pixel formats are passed in, its GPU renderer will crash outright.

#image("images/gui-survey-2026/ribir.png", width: 25em)

IME works properly, which is good. But the screen reader cannot recognize the contents of the window.

Although I have been criticizing how cryptic its macro syntax is, that is from the perspective of a programmer. When it comes to conciseness, Ribir's system is truly second to none. Among all the GUI frameworks I have surveyed so far, it seems to require the fewest lines of code. If Ribir could replace some of its notation with a more intuitive version, I would not hesitate to admit that this is a good design.

#details(summary: "Full Code", fullwidth[
  ```rust
  use ribir::prelude::*;

  pub fn qr_encode(text: &str) -> anyhow::Result<Vec<u8>> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<::image::Rgba<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(
          &mut std::io::Cursor::new(&mut buf),
          ::image::ImageFormat::WebP,
      )?;
      Ok(buf)
  }

  fn main() {
      App::run(fn_widget! {
          let mut input = @Input {};
          let image = Stateful::new(None);
          @Column{
              @Text {
                  text: "Enter text to generate QR code:"
              }
              @(input) {
                  on_chars: move |_| {
                      let input = $read(input);
                      let text = input.text();
                      *$write(image) = qr_encode(text).ok().and_then(|d| Image::new(d).ok());
                  }
              }
              @ { pipe!($read(image).clone()) }
          }
      })
      .with_title("QR Code Generator");
  }
  ```
])

== Rinf

#link("https://cunarist.github.io/rinf/")[Rinf] is another framework that uses Flutter as the interface for Rust programs.
I first learned about Rinf because of the #link("https://www.reddit.com/r/rust/comments/191b2to/comment/kgvgspl/")[plagiarism controversy] between it and Flutter Rust Bridge a few years ago.
But now that the controversy has settled down, we can take a good look at this library.

According to rinf's documentation, it recommends managing all application state in Rust, with Flutter used only for the UI. Specifically, it suggests using the Actor model in Rust to manage application state.

In this simple example, comparing the code written with rinf to Flutter Rust Bridge, it feels that under rinf's model, I can write Flutter code in a way that is more idiomatic to Flutter. Data is passed from Flutter to Rust through asynchronous functions; state is computed and managed on the Rust side, and then passed back to Flutter as subscribable streams. In this process, all the models are ones that Flutter already has natively, unlike Flutter Rust Bridge, which reinvents a pattern for managing state in Flutter.
Of course, this applies to cases where you want to manage all state on the Rust side. Flutter Rust Bridge, on the other hand, is probably better suited to scenarios where state is managed in Flutter, and Rust is used only to write functions that are called by Flutter.

Since the UI is the same as the Flutter Rust Bridge version, screenshots aren't included here for comparison.

#details(summary: "Full Code", fullwidth[
  Rust:
  ```rust
  use messages::prelude::{Actor, Address, Context, Notifiable};
  use rinf::{DartSignal, RustSignalBinary};
  use serde::{Deserialize, Serialize};

  #[derive(Deserialize, DartSignal)]
  pub struct TextChanged {
      pub text: String,
  }

  #[derive(Serialize, RustSignalBinary)]
  pub struct QrCodeGen;

  pub struct FirstActor;
  impl Actor for FirstActor {}

  impl FirstActor {
      pub fn new(address: Address<Self>) -> Self {
          tokio::spawn(Self::listen_to_dart(address));
          Self
      }

      async fn listen_to_dart(mut address: Address<Self>) {
          let receiver = TextChanged::get_dart_signal_receiver();
          while let Some(signal_pack) = receiver.recv().await {
              let _ = address.notify(signal_pack.message).await;
          }
      }
  }

  #[async_trait::async_trait]
  impl Notifiable<TextChanged> for FirstActor {
      async fn notify(&mut self, message: TextChanged, _: &Context<Self>) {
          if let Ok(png) = encode_qr(&message.text) {
              QrCodeGen.send_signal_to_dart(png);
          }
      }
  }

  fn encode_qr(text: &str) -> anyhow::Result<Vec<u8>> {
      let image = qrcode::QrCode::new(text.as_bytes())?
          .render::<image::Luma<u8>>()
          .build();
      let mut png = Vec::new();
      image.write_to(&mut std::io::Cursor::new(&mut png), image::ImageFormat::Png)?;
      Ok(png)
  }
  ```

  Flutter:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_hooks/flutter_hooks.dart';
  import 'package:rinf/rinf.dart';
  import 'src/bindings/bindings.dart';

  Future<void> main() async {
    await initializeRust(assignRustSignal);
    runApp(const MyApp());
  }

  class MyApp extends HookWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      final image = useStream(QrCodeGen.rustSignalStream).data?.binary;
      return MaterialApp(
        title: 'QR Code Generator',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.indigo)),
        home: Scaffold(
          body: Column(
            children: [
              const Text("Enter text to generate QR code:"),
              TextField(
                onChanged: (text) => TextChanged(text: text).sendSignalToRust(),
              ),
              if (image != null) Image.memory(image, width: 200, height: 200),
            ],
          ),
        ),
      );
    }
  }
  ```
])

== Rosin

#link("https://docs.rs/rosin/latest/rosin/")[Rosin] is also a GUI framework that emerged in 2026. Like the Elm Architecture, it centralizes all state at the top of the program. However, unlike Elm, it uses fine-grained reactivity to handle state updates. In addition, it supports styling programs with CSS, which is indeed a novel approach for a GUI library that draws its own widgets.

I originally thought rosin could not accomplish this task, because it has no image widget and does not support loading images in CSS background-image either. But when I tried the next framework, rui, which requires manual drawing on a canvas, I was inspired. So I went back and re-examined rosin's API. I discovered that rosin provides an `on_canvas` method for each component node, which exposes the vello context used for drawing that node, so I can manually draw images in it.

#image("images/gui-survey-2026/rosin.png", width: 25em)

IME works properly, and after adding some code to set up accessibility, the screen reader can also recognize the contents of the window. This is quite a good achievement for a framework that is just getting started.

However, rosin still has a ways to go. The current model allows for highly flexible custom components, but the built-in components are still not very rich. Also, rosin's default styles strongly assume dark mode. If you don't separately style a text box, its default font color is unreadable against its default background.

#details(summary: "Full Code", fullwidth[
  ```rust
  use std::{str::FromStr, sync::Arc};

  use rosin::{
      kurbo::Affine,
      peniko::{Blob, ImageAlphaType, ImageBrush, ImageData, ImageFormat, ImageQuality},
      prelude::*,
      widgets::*,
  };

  struct State {
      style: Stylesheet,
      input: TextBox,
      text: Var<String>,
  }

  impl Default for State {
      fn default() -> Self {
          Self {
              style: Stylesheet::from_str(".input { color: #fff; font-family: Hiragino Sans GB; }")
                  .unwrap(),
              input: TextBox::default(),
              text: Var::default(),
          }
      }
  }

  fn main_view(state: &State, ui: &mut Ui<State, WindowHandle>) {
      let text = state.text.downgrade();
      ui.node().style_sheet(&state.style).children(|ui| {
          label(ui, id!(), "Enter text to generate QR code:").on_accessibility(|_, a| {
              a.node.set_role(rosin::accesskit::Role::Label);
              a.node.set_value("Enter text to generate QR code:");
          });
          state
              .input
              .view(ui, id!(), state.text.downgrade())
              .classes("input");
          ui.node()
              .on_canvas(move |_, canvas| draw_qr(canvas, &text.get_or(String::new())));
      });
  }

  fn draw_qr(canvas: &mut CanvasCtx<'_>, text: &str) {
      let Ok(code) = qrcode::QrCode::new(text.as_bytes()) else {
          return;
      };
      let b = canvas.padding_box();
      let image = code.render::<image::Rgba<u8>>().build();
      let image = ImageData {
          width: image.width(),
          height: image.height(),
          data: Blob::new(Arc::new(image.into_raw())),
          format: ImageFormat::Rgba8,
          alpha_type: ImageAlphaType::Alpha,
      };
      let scale = b.width().min(b.height()) / image.width.min(image.height) as f64;
      canvas.scene.draw_image(
          &ImageBrush::new(image).with_quality(ImageQuality::Low),
          Affine::scale(scale),
      );
  }

  fn main() {
      let window = WindowDesc::new(callback!(main_view))
          .title("QR Code Generator")
          .size(400, 300);
      AppLauncher::new(window)
          .run(State::default(), TranslationMap::default())
          .expect("Failed to launch");
  }
  ```
])

== Rui

#link("https://docs.rs/rui/latest/rui/")[Rui] is an "experimental declarative UI library."
It has been over three years since rui's last release, and it is a pity to see it still in an experimental state. However, I noticed that rui's GitHub repository became active again last year, and perhaps we will see its next version soon.

Rui's design is inspired by SwiftUI and adopts a reactive programming model. Rui was created by the author to port their music workstation Audulus to Rust. Although Audulus is not open source, I cannot know its specific implementation. However, based on the fact that it is available on the App Store, as well as other discussions in the rui documentation, I infer that Audulus was developed with SwiftUI.

In the README, the author mentions some of the rationale behind rui's design. For example, SwiftUI's extensive texture caching is no longer necessary on modern GPUs, while for lightweight tasks such as layout, although they cannot be accelerated by the GPU, there is no need to cache them in the widget tree. Although I had a hard time understanding this long passage because I have no experience developing GUI frameworks, it is always a good thing to see the author actively communicating their design rationale.

However, rui does not have an image widget; it only has a canvas that can draw using vector operations. So I need to convert the QR code into a series of drawing commands and then draw them onto rui's canvas.

#image("images/gui-survey-2026/rui.png", width: 25em)

Neither IME nor screen reader is supported.
After analyzing rui's source code with AI, I found that rui's accessibility support is only partially implemented. They generate accessibility information for widget nodes, but do not submit it to the system.

For such a simple task, rui's code is extremely concise. I feel that if rui could add support for pixel images, this task could even be completed in under 20 lines.

#details(summary: "Full Code", fullwidth[
  ```rust
  use rui::*;

  fn main() {
      state(String::new, |text, cx| {
          vstack((
              "Enter text to generate QR code:".padding(Auto),
              text_editor(text).padding(Auto),
              qr_code_view(cx[text].clone()).padding(Auto),
          ))
      })
      .window_title("QR Code Generator")
      .run()
  }

  fn qr_code_view(text: String) -> impl View {
      let (n, modules) = qrcode::QrCode::new(text.as_bytes())
          .map(|code| (code.width(), code.to_colors()))
          .unwrap_or_default();

      canvas(move |_, rect, vger| {
          let size = rect.size.width.min(rect.size.height) / (n as f32 + 8.0);
          let (white, black) = (vger.color_paint(WHITE), vger.color_paint(BLACK));
          vger.fill_rect(rect, 0.0, white);
          for (i, &color) in modules.iter().enumerate() {
              if color == qrcode::Color::Dark {
                  let (x, y) = (i % n, i / n);
                  let p = rect.origin
                      + LocalOffset::new((x as f32 + 4.0) * size, (n + 3 - y) as f32 * size);
                  vger.fill_rect(LocalRect::new(p, LocalSize::new(size, size)), 0.0, black);
              }
          }
      })
      .size([280.0, 280.0])
  }
  ```
])

== SDL3

The #link("https://docs.rs/sdl3/latest/sdl3/")[sdl3] crate is a Rust binding for the well-known graphics library SDL3. It is a bit strange to include this crate in Are We GUI Yet?, because it can hardly be considered a GUI framework. It merely provides a canvas on which you can draw freely. Although you can draw the widgets you want in it, you need to implement layout, event handling, state management, and other functionality yourself, none of which SDL3 can provide for you.

Rather than Are We GUI Yet?, SDL3 should appear in Are We Game Yet? #footnote[It #link("https://arewegameyet.rs/ecosystem/2drendering/")[indeed is].] instead.

== Slint

#link("https://slint.dev/docs")[Slint] is a GUI framework that I have always been very fond of; it can basically be considered the Rust version of Qt. It supports multiple platforms such as desktop, mobile, embedded, and Web, and provides bindings for C++, Rust, Node.js, and Python.

Slint uses a dedicated language also called slint as a DSL for writing UIs, which is almost identical to QML in this respect. It also adopts a reactive model based on two-way bindings.
Designing a dedicated language to describe GUIs has both advantages and disadvantages compared with keeping all the logic in the host language. The advantage is that you can have syntax and semantics that are better suited to describing GUIs.
Another benefit is that you can build an ecosystem around the language itself, such as interface editors, live previews#footnote[Slint's live previewer is quite handy; it would be even better if it could support displaying CJK characters.], and so on.
The disadvantage is that cross-language interaction inevitably introduces friction, especially when logic and state are tightly coupled, requiring you to switch frequently between the two languages.

#image("images/gui-survey-2026/slint.png", width: 25em)

Both IME and screen reader work properly.

Slint's VS Code extension can provide code completion and preview support for slint files, and even for slint code snippets embedded in Rust via slint macros. This is undoubtedly a great boost to the developer experience.

In community discussions on Reddit, slint is not as popular as iced or egui. Considering how complete its feature set is, I feel slint deserves more traction. Part of the reason may be that slint adopts a semi-commercial open-source licensing model similar to Qt's. But this is actually a common practice in the open-source software world, and we shouldn't be overly critical of normal commercial behavior.

#details(summary: "Full Code", fullwidth[
  ```rust
  use slint::{Image, Rgb8Pixel, SharedPixelBuffer};

  slint::slint! {
      import { VerticalBox } from "std-widgets.slint";

      export component AppWindow inherits Window {
          title: "QR Code Generator";
          in-out property <string> text <=> input.text;
          in-out property <image> qr <=> img.source;
          callback text-changed(value: string);
          changed text => {
              root.text-changed(text);
          }
          VerticalBox {
              Text {
                  text: "Enter text to generate QR code:";
              }

              input := TextInput { }

              img := Image {
                  width: 200px;
                  height: 200px;
              }
          }
      }
  }

  pub fn qr_encode(text: &str) -> anyhow::Result<Image> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Rgb<u8>>().build();
      let buffer =
          SharedPixelBuffer::<Rgb8Pixel>::clone_from_slice(img.as_raw(), img.width(), img.height());
      Ok(Image::from_rgb8(buffer))
  }

  fn main() -> anyhow::Result<()> {
      let ui = AppWindow::new()?;

      let ui_handle = ui.as_weak();
      ui.on_text_changed(move |text| {
          if let Some(ui) = ui_handle.upgrade()
              && let Ok(qr) = qr_encode(&text)
          {
              ui.set_qr(qr);
          }
      });

      ui.run()?;

      Ok(())
  }
  ```
])

== Tauri

People often describe #link("https://tauri.app/")[Tauri] as a lightweight Electron written in Rust.

Tauri emerged around the same time as Windows WebView2. Its original goal was to solve the problem of Electron apps bundling an entire Chrome browser and taking up a large amount of disk space. Because Tauri uses the system WebView directly, Tauri apps can be kept very small.

However, Tauri still inherits all the drawbacks of WebView, such as high memory usage and the unavoidable IPC and cross-language friction between the browser and the backend.

Since Tauri can indeed be used to build GUIs for Rust programs, people often compare it with other GUI frameworks. But I think this comparison is somewhat risky. Before you even decide to add a GUI to a program, whether to choose a Web UI is a fundamental fork in the road. State management is usually tightly coupled with the interface. Once you choose a Web UI, you have to start thinking about managing program state on the frontend. And the frontend is often a different language; even if you write the frontend in Rust, you still need to consider the IPC boundary between frontend and backend.

Boringcactus sharply criticized the type safety of Tauri IPC in hir post. Ze then mentioned that ze learned at the Utah Rust meetup about a project called tauri-specta that can improve IPC type safety between Rust and TypeScript. Although this is a survey about Rust GUIs, and writing the interface in TypeScript may be somewhat off-topic, let's still take a look at how much tauri-specta can improve type safety.

#image("images/gui-survey-2026/tauri.png", width: 25em)

There's nothing much to say about the interface; both IME and screen reader work properly.

The way tauri-specta works is simpler than expected. It collects every function annotated with `#[specta]`, parses its type, and exports it in a TypeScript stub file. This stub file contains typed wrappers for Tauri IPC, allowing correct types to be used in TypeScript. Although it sounds simple, it is indeed an effective approach. It would be great if the Tauri team could integrate this solution into their system.

#details(summary: "Full Code", fullwidth[
  Rust:
  ```rust
  use base64::Engine;
  use specta_typescript::Typescript;
  use tauri_specta::{collect_commands, Builder};

  #[tauri::command]
  #[specta::specta]
  fn generate_qr_code(text: &str) -> Result<String, String> {
      qr_encode_data_url(text).map_err(|e| e.to_string())
  }

  fn qr_encode_data_url(text: &str) -> anyhow::Result<String> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code
          .render::<image::Luma<u8>>()
          .min_dimensions(256, 256)
          .build();

      let mut png = Vec::new();
      img.write_to(&mut std::io::Cursor::new(&mut png), image::ImageFormat::Png)?;

      let b64 = base64::engine::general_purpose::STANDARD.encode(&png);
      Ok(format!("data:image/png;base64,{b64}"))
  }

  fn main() {
      let builder = Builder::<tauri::Wry>::new().commands(collect_commands![generate_qr_code]);

      builder
          .export(Typescript::default(), "../src/bindings.ts")
          .expect("Failed to export typescript bindings");

      tauri::Builder::default()
          .invoke_handler(builder.invoke_handler())
          .setup(move |app| {
              builder.mount_events(app);

              Ok(())
          })
          .run(tauri::generate_context!())
          .expect("error while running tauri application");
  }
  ```

  TypeScript:
  ```tsx
  import { useEffect, useState } from "react";
  import { commands } from "./bindings";

  function App() {
    const [text, setText] = useState("");
    const [qrCode, setQrCode] = useState("");

    useEffect(() => {
      commands.generateQrCode(text).then((value) => {
        if (value.status === "ok") {
          setQrCode(value.data);
        }
      });
    }, [text]);

    return (
      <main
        style={{
          display: "flex",
          flexDirection: "column",
          gap: "1rem",
          padding: "1rem",
        }}
      >
        <p>Enter text to generate QR code:</p>
        <input
          id="greet-input"
          value={text}
          onChange={(e) => setText(e.currentTarget.value)}
          placeholder="https://example.com"
        />
        <img src={qrCode} alt="Generated QR Code" />
      </main>
    );
  }

  export default App;
  ```
])

== Tessera

#quote[#link("https://docs.rs/tessera-ui/latest/tessera_ui/")[Tessera] is a declarative, immediate-mode UI framework for Rust that emphasizes performance, flexibility, and extensibility through a functional approach and pluggable shader system.]

Tessera is also a very new UI framework. Its first version was released in July 2025, and it has now reached version 2.5.0. According to a #link("https://tessera-ui.github.io/blog/positional-memoization-via-proc-macros.html")[blog post] included in its documentation, Tessera is working on implementing Material Design as a milestone for version 3.0.
From that blog post, I get the impression that Tessera has some unique insights into state management for immediate mode GUIs.

However, when I tried it, Tessera could not run on macOS, encountering some errors from wgpu. Hopefully, once it fixes its platform compatibility, we can meet again someday.

== Tinyfiledialogs

#link("https://docs.rs/tinyfiledialogs/latest/tinyfiledialogs/")[Tinyfiledialogs] provides a Rust binding for a C library that offers various small dialogs. It cannot be considered a complete GUI framework, but it does provide some GUI functionality. Its features are not sufficient to accomplish today's task.

A crate with a similar positioning is #link("https://docs.rs/rfd/latest/rfd/")[rfd], but it is not included on Are We GUI Yet?.

== Tk

#link("https://docs.rs/tk/latest/tk/")[Tk] is the Rust binding for Tcl/Tk. I suspect most people's first exposure to Tcl/Tk comes from the rather idiosyncratic tkinter module in Python's standard library.

Although Python's standard library bundles Tk 8.6, using the Tk crate requires having Tk 8.6 installed on your system beforehand. If the version is mismatched -- for instance, on my first attempt, the system Tk on macOS was 8.5, which led to some strange compilation errors.

The Tk crate employs clever operator overloading to faithfully replicate the distinctive syntax of Tk commands. If you have a genuine fondness for the Tcl language, you'll appreciate this design. However, what would likely suit most developers better is to use the host language idiomatically, as Python's tkinter does. In Rust, for example, the builder pattern would be a more natural fit.

#image("images/gui-survey-2026/tk.png", width: 25em)

IME works properly, but the screen reader cannot recognize the contents of the window. This is somewhat disappointing, since Tcl/Tk is a long-established UI toolkit and one would expect it to be mature in all respects. However, its age may be a factor: accessibility was not yet a consideration when it was originally designed.

As for the development experience with the Tk crate, despite the author's thorough tutorial, it still falls short of covering everything needed for real-world GUI development. During development, I found it easier to consult Python's tkinter documentation instead. The crate also contains several patterns that are quite unidiomatic in Rust. For instance, the `tclosure` macro matches closure parameters by name, so an incorrect parameter name results in a runtime error. This was not at all obvious when I first wrote the code.

#details(summary: "Full Code", fullwidth[
  ```rust
  use base64::Engine as _;
  use tcl::*;
  use tk::cmd::*;
  use tk::*;

  pub fn qr_encode(text: &str) -> anyhow::Result<String> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<::image::Luma<u8>>().build();

      let mut buf = Vec::new();
      img.write_to(
          &mut std::io::Cursor::new(&mut buf),
          ::image::ImageFormat::Png,
      )?;
      Ok(base64::engine::general_purpose::STANDARD.encode(buf))
  }

  fn main() -> TkResult<()> {
      let tk = make_tk!()?;
      let root = tk.root();
      root.set_wm_title("QR Code Generator")?;

      root.add_ttk_label(-text("Enter text to generate QR code:"))?
          .pack(())?;
      let qr_image = tk.image_create_photo("qr")?;
      let update = tcl::tclosure!(tk, |vldt_new: String| -> TkResult<bool> {
          let interp = tcl_interp!();
          if let Ok(qr) = qr_encode(&vldt_new) {
              interp.run(("qr", "configure", "-data", qr))?;
          } else {
              interp.run(("qr", "blank"))?;
          }
          Ok(true)
      });
      root.add_ttk_entry(-validate("key") - validatecommand(update))?
          .pack(())?;
      root.add_ttk_label("preview" - image(qr_image))?.pack(())?;

      Ok(main_loop())
  }
  ```
])

== Undoredo

#link("https://docs.rs/undoredo")[Undoredo] is not a GUI library. It provides incremental updates, snapshots, and rollback capabilities for various container data structures.

I suspect it is listed on Are We GUI Yet? because it can be used to implement state management in GUI applications. However, placing it alongside other GUI libraries still feels somewhat out of place. Are We GUI Yet? should seriously consider categorizing the crates on its site, similar to how Are We Game Yet? does.

== Vizia

#link("https://docs.vizia.dev/vizia/")[Vizia] is a declarative Rust GUI framework built on a fine-grained reactivity model, with skia as its rendering backend.

I ran into a few hurdles while implementing today's task with Vizia. Vizia does provide an `Image` widget, but it is not fully implemented. Although `Image` accepts a `Signal` as a parameter, it is not reactive; it only reads the state once at creation. Moreover, while the documentation states that `Image` can load URLs, examining the implementation revealed that data URLs are not supported. As a result, I had to use the SVG widget to render the QR code instead. Unfortunately, the SVG widget has the same reactivity limitation, so I had to wrap the entire widget in a `Binding` to make it respond to `Signal` changes and trigger redraws.

#image("images/gui-survey-2026/vizia.png", width: 25em)

IME works correctly, but when I tried to use a screen reader to inspect the window contents, the program crashed immediately.

This was quite unexpected. With the help of AI, I traced the cause of the crash.
In the `Textbox`'s `on_edit` event, modifying the `Signal` that the text widget itself listens to leaves some internal accessibility information stale. When the screen reader then tries to access it, an out-of-bounds access occurs. The workaround is to avoid passing a listenable signal to the `Textbox`. However, that introduces another bug: when the text box loses focus, its content disappears because the state update is not propagated back to the widget.
This looks like a catch-22. If you handle the state correctly, the screen reader breaks. But if you make the screen reader work, the text box's state cannot be managed properly.

#details(summary: "Full Code", fullwidth[
  ```rust
  use vizia::prelude::*;

  fn qr_svg(text: &str) -> anyhow::Result<String> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let mut renderer = code.render::<qrcode::render::svg::Color>();
      renderer.min_dimensions(200, 200);
      Ok(renderer.build())
  }

  fn main() -> anyhow::Result<()> {
      Application::new(|cx| {
          let text = Signal::new(String::new());
          let image = Signal::new(None);

          VStack::new(cx, |cx| {
              Label::new(cx, "Enter text to generate QR code:");
              Textbox::new(cx, text)
                  .width(Pixels(200.0))
                  .on_edit(move |_, new_text| {
                      *image.write() = qr_svg(&new_text).ok();
                      *text.write() = new_text;
                  });
              Binding::new(cx, image, move |cx| {
                  if let Some(image) = image.get() {
                      Svg::new(cx, image)
                          .size(Pixels(200.0))
                          .fill(Color::transparent())
                          .hoverable(false);
                  }
              });
          })
          .alignment(Alignment::Center);
      })
      .title("QR Code Generator")
      .inner_size((400, 400))
      .run()?;
      Ok(())
  }
  ```
])

== WebRender

#link("https://docs.rs/webrender/latest/webrender/")[WebRender] is the rendering engine behind Mozilla Firefox and Servo, the browser written in Rust. Its documentation on docs.rs is severely outdated and gives little sense of the library's actual state. I can't help but wonder how the Servo developers manage to work under such conditions.

WebRender provides only drawing APIs, and as its wiki notes, these are specialized for browser use cases, which makes it difficult to use the library as a general-purpose GUI framework.

== Windows

#link("https://microsoft.github.io/windows-docs-rs/")[Rust for Windows] is a highly ambitious project. Microsoft aims to provide comprehensive Rust bindings for the entire Windows API surface. By using the `windows` crate, and the `windows-sys` crate as supplementary, you can call any Windows API directly from Rust. This naturally includes the various GUI frameworks available on Windows, such as Win32 UI and Composition UI.

Calling Windows APIs directly to create GUI interfaces is far too tedious. Even a decade or more ago, nobody would have done such a thing. However, the Rust for Windows repository recently gained a new framework called `windows-reactor`, which provides a reactive programming layer on top of WinUI 3, making it as convenient to develop with as other Rust GUI frameworks.
I'm somewhat curious about it, so let me spin up a Windows VM and see what the development experience with `windows-reactor` is like.

== Windows Reactor

Though #link("https://github.com/microsoft/windows-rs/tree/master/crates/libs/reactor")[Windows Reactor] is not listed on Are We GUI Yet?, I decided to try it anyway, both for the reasons above and out of curiosity.

Windows Reactor's state management model is nearly identical to React's. It replicates hooks like `useState` and `useRef`, and, like React, it stores hook data according to call order. Since Dioxus, another React-inspired library, has moved toward a signal-based reactivity model, Windows Reactor is arguably now the Rust GUI library that most closely resembles React.

Overall, its API surface is relatively complete, but there are still some rough edges. For instance, to display an in-memory image, I had to create a canvas and draw the bitmap onto it. Initially, I assumed I would need to use Direct2D APIs directly for drawing. Later, with AI assistance, I found that the `windows-canvas` crate offers a simpler interface for this purpose.

#image("images/gui-survey-2026/windows-reactor.png", width: 20em)

IME input works as expected. Windows Narrator can read the contents of text boxes but fails to recognize text labels. I'm unsure whether this is because I didn't set the appropriate accessibility flags in the code, or because Windows Reactor's accessibility support is still incomplete.

#details(summary: "Full Code", fullwidth[
  ```rust
  use windows_canvas::{ColorF, GpuDevice, Rect};
  use windows_reactor::*;

  fn app(cx: &mut RenderCx) -> Element {
      let (image, set_image) = cx.use_state(ImageSource::None);

      vstack((
          text_block("Enter text to generate QR code:"),
          text_box(String::new()).on_text_changed(move |text: String| {
              set_image.call(build_qr_surface(&text).unwrap_or_default())
          }),
          Image::new(image).width(200.).height(200.),
      ))
      .spacing(12.0)
      .into()
  }

  fn build_qr_surface(text: &str) -> anyhow::Result<ImageSource> {
      let img = qrcode::QrCode::new(text.as_bytes())?
          .render::<::image::Rgba<u8>>()
          .build();
      let (width, height) = img.dimensions();
      let device = GpuDevice::new_or_warp()?;
      let surface = CanvasImageSource::new(&device, 200., 200., 1.0)?;
      let _ = surface.draw(ColorF::WHITE, |session| {
          session.draw_bitmap(
              &session.create_bitmap(&img.into_raw(), width, height)?,
              &Rect::from_xywh(0., 0., width as f32, height as f32),
              1.0,
          );
          Ok(())
      })?;
      Ok(surface.image_source())
  }

  fn main() -> windows_core::Result<()> {
      bootstrap()?;
      App::new().title("QR Code Generator").render(app)
  }
  ```
])

== WinSafe

#link("https://docs.rs/winsafe/latest/winsafe/")[WinSafe] is a Rust binding for the Win32 API, and it offers a high-level, idiomatic abstraction layer for Win32 GUI programming.
Interestingly, this library has no dependencies, not even the `windows` crate, since WinSafe's history predates it.

Now that I have a Rust development environment set up in the Windows VM, let’s give this library a try as well.

#image("images/gui-survey-2026/winsafe.png", width: 20em)

The UI has the familiar, reassuring Win32 look. Both the screen reader and IME work flawlessly.

While most of WinSafe's API can be used from safe Rust, a few features still lack safe wrappers and require calling the underlying Win32 APIs through `unsafe` code. Setting the image on a Label in this task is one such case.

#details(summary: "Full Code", fullwidth[
  ```rust
  use std::cell::Cell;
  use winsafe::{self as w, gui, msg, prelude::*};

  fn main() -> w::AnyResult<()> {
      let wnd = gui::WindowMain::new(gui::WindowMainOpts {
          title: "QR Code Generator",
          size: gui::dpi(224, 283),
          ..Default::default()
      });
      let _ = gui::Label::new(
          &wnd,
          gui::LabelOpts {
              text: "Enter text to generate QR code:",
              position: gui::dpi(12, 12),
              ..Default::default()
          },
      );
      let input = gui::Edit::new(
          &wnd,
          gui::EditOpts {
              position: gui::dpi(12, 41),
              width: gui::dpi_x(200),
              ..Default::default()
          },
      );
      let image = gui::Label::new(
          &wnd,
          gui::LabelOpts {
              text: "",
              position: gui::dpi(12, 71),
              size: gui::dpi(200, 200),
              control_style: w::co::SS::BITMAP | w::co::SS::CENTERIMAGE,
              ..Default::default()
          },
      );
      let (edit, image) = (input.clone(), image.clone());
      let bitmap = Cell::new(None);
      input.on().en_change(move || {
          let next = qrcode::QrCode::new(edit.text()?.as_bytes())
              .ok()
              .map(|qr| {
                  let img = qr
                      .render::<image::Rgba<u8>>()
                      .max_dimensions(gui::dpi_x(200) as _, gui::dpi_y(200) as _)
                      .build();
                  let (width, height) = img.dimensions();
                  let mut bits = img.into_raw();
                  w::HBITMAP::CreateBitmap(
                      w::SIZE::with(width as _, height as _),
                      1,
                      32,
                      bits.as_mut_ptr(),
                  )
              })
              .transpose()?;
          let handle = unsafe { next.as_deref().unwrap_or(&w::HBITMAP::NULL).raw_copy() };
          let _ = unsafe {
              image.hwnd().SendMessage(msg::StmSetImage {
                  image: w::BmpIconCurMeta::Bmp(handle),
              })
          };
          bitmap.set(next);
          Ok(())
      });
      wnd.run_main(None)?;
      Ok(())
  }
  ```
])

== WxDragon

#link("https://docs.rs/wxdragon/latest/wxdragon/")[WxDragon] is a Rust binding for wxWidgets, a widely used GUI toolkit. Considering wxWidgets' prominence in the Python ecosystem, it is somewhat surprising that a Rust binding did not appear until 2025.

#image("images/gui-survey-2026/wxdragon.png")

Both IME input and screen reader functionality work as expected.

Apart from wxWidgets' somewhat idiosyncratic widget naming conventions, there is little to fault in this binding. Despite being relatively new, it already covers virtually every aspect of wxWidgets. Since wxWidgets itself is a mature toolkit, I see no issue with using this binding in a production environment.

#details(summary: "Full Code", fullwidth[
  ```rust
  use wxdragon::prelude::*;

  pub fn qr_encode(text: &str) -> Option<Bitmap> {
      let code = qrcode::QrCode::new(text.as_bytes()).ok()?;
      let img = code.render::<image::Rgba<u8>>().build();
      Bitmap::from_rgba(img.as_raw(), img.width(), img.height())
  }

  fn main() -> Result<(), Box<dyn std::error::Error>> {
      wxdragon::main(|_| {
          let frame = Frame::builder().with_title("QR Code Generator").build();

          let sizer = BoxSizer::builder(Orientation::Vertical).build();

          let label = StaticText::builder(&frame)
              .with_label("Enter text to generate QR code:")
              .build();
          sizer.add(&label, 1, SizerFlag::AlignCenterHorizontal, 0);

          let input = TextCtrl::builder(&frame).build();
          sizer.add(&input, 1, SizerFlag::AlignCenterHorizontal, 0);

          let image = StaticBitmap::builder(&frame)
              .with_bitmap(qr_encode(""))
              .build();
          sizer.add(&image, 1, SizerFlag::AlignCenterHorizontal, 0);

          input.on_text_changed(move |ev| {
              if let Some(qr) = ev.get_string().and_then(|text| qr_encode(&text)) {
                  image.set_bitmap(&qr)
              }
          });

          frame.set_sizer(sizer, true);
          frame.show(true);
      })
  }
  ```
])

== Xilem

Finally, we are almost at the tail end of this list.

#link("https://docs.rs/xilem/latest/xilem/")[Xilem] is a reactive Rust GUI framework built on the previously mentioned Masonry, and it provides a reactive user-interface layer on top of it.

Xilem has a #link("https://raphlinus.github.io/rust/gui/2022/05/07/ui-architecture.html")[blog post] explaining their understanding of implementing reactive GUI interfaces in Rust.
It is an excellent article and is very helpful for understanding reactive GUI frameworks, as well as why many Rust GUI frameworks are designed the way they are. After reading it, I did see traces of the ideas proposed by Xilem in some of the frameworks I encountered in this survey, such as how blinc and KAS handle stateful components.

Floem mentions in its documentation that it was also influenced by Xilem, and Xilem says in its blog that its design was influenced by rui. I think it would be interesting if someone could organize the relationships of mutual influence among these Rust GUI frameworks into a diagram similar to a biological evolutionary tree.

#image("images/gui-survey-2026/xilem.png")

Like the underlying Masonry, IME and screen reader are both available. However, because Xilem does not expose Masonry's interface for setting the font for text input, CJK characters in text input cannot be displayed correctly.

#details(summary: "Full Code", fullwidth[
  ```rust
  use xilem::masonry::peniko::{ImageAlphaType, ImageData};
  use xilem::view::{flex_col, image, label, text_input};
  use xilem::{EventLoop, ImageFormat, WidgetView, WindowOptions, Xilem};

  fn qr_encode(text: &str) -> anyhow::Result<ImageData> {
      let code = qrcode::QrCode::new(text.as_bytes())?;
      let img = code.render::<image::Rgba<u8>>().build();
      let (width, height) = img.dimensions();
      Ok(ImageData {
          data: img.into_raw().into(),
          format: ImageFormat::Rgba8,
          alpha_type: ImageAlphaType::AlphaPremultiplied,
          width,
          height,
      })
  }

  fn app_logic(text: &mut String) -> impl WidgetView<String> + use<> {
      flex_col((
          label("Enter text to generate QR code:"),
          text_input(text.clone(), |text, new_text| *text = new_text),
          qr_encode(text).ok().map(image),
      ))
  }

  fn main() -> anyhow::Result<()> {
      let app = Xilem::new_simple(
          String::new(),
          app_logic,
          WindowOptions::new("QR Code Generator"),
      );
      app.run_in(EventLoop::with_user_event())?;
      Ok(())
  }
  ```
])

== Yew

#link("https://docs.rs/yew/")[Yew] is a React-style framework for developing web apps, and like Leptos, it does not have native desktop GUI support.

== Conclusion <conclusion>

Well, it is time to bring this long journey to a close and, in doing so, single out the winners of this survey, or, to put it more modestly, the frameworks I would be willing to use.

In the winners' circle are slint and egui. Beyond having APIs free of obvious friction or pitfalls, they also provide solid support for IME and accessibility. They respectively occupy the two thrones of retained-mode UI and immediate-mode UI.

There are also frameworks that appeal to me in certain niche areas. For example, Crux paired with SwiftUI, and rinf paired with Flutter. And if I were willing to adopt a WebView, Dioxus or Tauri + `tauri-spectra` would be reasonable choices.

Other frameworks fall just short of the winners' circle due to minor drawbacks, cushy, Freya, Floem, Iced, Relm4, and Xilem, for instance. I also find their API designs quite appealing. Unfortunately, they are somewhat lacking in input method or accessibility support. Should they continue to improve in these areas, their future looks promising.

Of course, this survey is only a snapshot, and a rather subjective one. A framework that excels in this simple scenario may not necessarily handle more complex programs. Still, this exercise exposed the parts of GUI development that are hardest to fake. Rust has plenty of promising GUI projects, but the ecosystem has not yet converged on a universally accepted, boring choice.

I may also have made mistakes in this survey due to personal oversights. If you find anything I have written that does not match the facts, please contact me and point it out.

#details(summary: "Curious about the disk space this survey used?")[
  ```shell
  $ dust -d 1 .
  213M   ┌── windows-rs               │█           │   0%
  292M   ├── hello-qmetaobject        │█           │   0%
  568M   ├── hello-cacao              │█           │   1%
  597M   ├── hello-fltk               │█           │   1%
  659M   ├── hello-makepad            │█           │   1%
  744M   ├── hello-relm4              │█           │   1%
  769M   ├── hello-gtk4               │█           │   1%
  786M   ├── hello-tk                 │█           │   1%
  923M   ├── hello-ply                │█           │   1%
  939M   ├── hello-azul               │█           │   1%
  1.0G   ├── hello_flutter_rust_bridge│█           │   1%
  1.2G   ├── hello-relm               │█           │   1%
  1.5G   ├── hello_rinf               │█           │   2%
  1.6G   ├── hello-lvgl               │█           │   2%
  1.6G   ├── hello-cxx-qt             │█           │   2%
  1.7G   ├── hello-floem              │█           │   2%
  1.8G   ├── hello-cushy              │█           │   2%
  1.8G   ├── hello-fui                │█           │   2%
  1.8G   ├── hello-pane-ui            │█           │   2%
  1.8G   ├── hello-dioxus             │█           │   2%
  1.9G   ├── hello-gtk                │█           │   2%
  1.9G   ├── azul                     │█           │   2%
  1.9G   ├── hello-egui               │█           │   2%
  2.1G   ├── hello-xilem              │█           │   2%
  2.1G   ├── hello-gemgui             │█           │   2%
  2.1G   ├── hello-imgui              │█           │   2%
  2.2G   ├── hello-masonry            │█           │   2%
  2.2G   ├── hello-rui                │█           │   2%
  2.4G   ├── hello-tessera            │█           │   3%
  2.5G   ├── hello-freya              │█           │   3%
  2.8G   ├── hello-pax                │█           │   3%
  2.8G   ├── hello-iced               │█           │   3%
  3.0G   ├── hello-kas                │█           │   3%
  3.4G   ├── hello-vizia              │█           │   4%
  3.9G   ├── hello-rosin              │█           │   4%
  4.2G   ├── hello-slint              │█           │   4%
  4.6G   ├── hello-tauri              │█           │   5%
  4.6G   ├── hello-wxdragon           │█           │   5%
  5.0G   ├── hello-blinc              │█           │   5%
  5.1G   ├── hello-crux               │█           │   5%
  5.7G   ├── hello-gpui               │█           │   6%
  6.1G   ├── hello-ribir              │█           │   6%
   94G ┌─┴ .                          │███████████ │ 100%
  ```
]

#details(summary: "Some extra words about the user interface design")[
  GUI is a discipline of composition. A GUI consists of many components, each with its own functionality, and the framework's job is to ensure that, when combined, they can cooperate to deliver more complete functionality. This involves many forms of composition: component with component, component with state, and state with state.

  The manner of composition determines the shape of the user interface, because different components and different states typically have different types. To compose values of different types together, some non-trivial design is always required, whether through tuples or similar combinators (cushy, floem, xilem), through an imperative approach of inserting components into the interface one at a time (egui, rosin, vizia), through a degree of macro magic (iced, KAS, ribir), or even by inventing a dedicated language (slint).

  Some may argue that in 2026, with coding agents all the rage, interface designs no longer need to prioritize human readability. But that is no excuse for a framework author to abandon their aesthetic exploration. Only with a thorough, holistic understanding of the entire system's design, and from a high-level perspective, can one produce a user interface that is both concise and elegant. If a library offers only interfaces riddled with friction or obscurity, one may rightly question whether its author has made a genuine effort to explore this field.
]

== The Table <the-table>

_Edit on 2026-08-25: Added extra dependencies column._

#fullwidth(table(
  columns: 5,
  [*Library*], [*Usability*], [*Extra Deps*], [*Accessibility*], [*IME Support*],
  [#link("https://azul.rs")[Azul]], [😭 cannot read fonts], [], [], [],
  [#link("https://project-blinc.github.io/Blinc")[blinc]], [🟡 API friction], [], [❌ No], [🟡 composer position bad; CJK fonts unsupported],
  [#link("https://docs.rs/cacao/latest/cacao/")[cacao]], [✅ OK], [macOS only], [✅ OK], [✅ OK],
  [#link("https://docs.rs/core-foundation/latest/core_foundation/")[Core Foundation]], [😭 low-level API], [], [], [],
  [#link("https://redbadger.github.io/crux/")[Crux]], [✅ OK], [SwiftUI], [✅ OK], [✅ OK],
  [#link("https://docs.rs/cushy/latest/cushy/")[cushy]], [✅ OK], [], [❌ No], [🟡 composer hidden],
  [#link("https://kdab.github.io/cxx-qt/book/")[CXX-Qt]], [🟡 Nix compatibility], [Qt], [✅ OK], [✅ OK],
  [#link("https://docs.rs/dioxus/latest/dioxus/")[Dioxus]], [✅ OK], [WebView], [✅ OK], [✅ OK],
  [#link("https://docs.rs/dominator/latest/dominator/")[dominator]], [web only], [], [], [],
  [#link("https://docs.rs/egui/latest/egui/")[egui]], [✅ OK], [], [✅ OK], [🟡 CJK font setup],
  [#link("https://docs.rs/floem/latest/floem/")[floem]], [✅ OK], [], [❌ No], [❌ No],
  [#link("https://docs.rs/fltk")[FLTK]], [✅ OK], [FLTK (bundled)], [✅ OK (with extra setup)], [✅ OK],
  [#link("https://docs.rs/flutter_rust_bridge/latest/flutter_rust_bridge/")[Flutter Rust Bridge]], [✅ OK], [Flutter], [✅ OK], [✅ OK],
  [#link("https://docs.rs/freya/latest/freya/")[Freya]], [✅ OK], [], [❌ No], [✅ OK],
  [#link("https://github.com/marek-g/rust-fui/blob/master/doc/SUMMARY.md")[Fui]], [no macOS support], [], [], [],
  [#link("https://docs.rs/gemgui/latest/gemgui/")[gemgui]], [✅ OK], [Python & pywebview], [✅ OK], [✅ OK],
  [#link("https://www.gpui.rs/")[GPUI]], [🟡 no text input widget], [], [❌ I don't know how to get it work], [🟡 crash],
  [#link("https://longbridge.github.io/gpui-component/")[GPUI Component]], [✅ OK], [], [✅ OK], [✅ OK],
  [#link("https://gtk-rs.org/gtk3-rs/stable/latest/docs/gtk/")[GTK 3]], [🟡 use specific commit], [GTK3], [❌ No], [❌ No],
  [#link("https://gtk-rs.org/gtk4-rs/stable/latest/docs/gtk4")[GTK 4]], [✅ OK], [GTK4], [❌ No], [✅ OK],
  [#link("https://docs.rs/iced/latest/iced/")[iced]], [✅ OK], [], [❌ No], [✅ OK],
  [#link("https://docs.rs/imgui")[imgui]], [🟡 boilerplate], [], [❌ No], [❌ No],
  [#link("https://docs.rs/kas/")[KAS]], [🟡 API friction], [], [❌ No], [❌ No],
  [#link("https://docs.rs/kittest/latest/kittest/")[kittest]], [not a GUI framework], [], [], [],
  [#link("https://docs.rs/leptos/latest/leptos/")[Leptos]], [web only], [], [], [],
  [#link("https://docs.rs/lvgl/latest/lvgl/")[lvgl]], [🟡 embedded only], [], [❌ No], [❌ No],
  [#link("https://github.com/makepad/makepad")[Makepad]], [🟡 poor documentation], [], [❌ No], [🟡 composer hidden],
  [#link("https://docs.rs/masonry/latest/masonry/")[masonry]], [🟡 low-level], [], [✅ OK], [✅ OK],
  [#link("https://crates.io/crates/maycoon")[Maycoon]], [deprecated], [], [], [],
  [#link("https://docs.rs/pane_ui")[Pane UI]], [😭 cannot load images], [], [], [],
  [#link("https://www.pax.dev")[Pax]], [😭 failed to compile], [], [], [],
  [#link("https://plyx.iz.rs/docs/getting-started/")[ply]], [🟡 odd default values], [], [✅ OK (with extra setup)], [❌ No],
  [#link("https://docs.rs/qmetaobject/latest/qmetaobject/")[QMetaObject]], [🟡 Nix compatibility], [Qt], [✅ OK], [✅ OK],
  [#link("https://docs.rs/relm/")[Relm]], [✅ OK], [GTK3], [❌ No], [❌ No],
  [#link("https://docs.rs/relm4/")[Relm4]], [✅ OK], [GTK4], [❌ No], [✅ OK],
  [#link("https://ribir.org/docs/introduction")[Ribir]], [🟡 cryptic macros], [], [❌ No], [✅ OK],
  [#link("https://cunarist.github.io/rinf/")[rinf]], [✅ OK], [Flutter], [✅ OK], [✅ OK],
  [#link("https://docs.rs/rosin/latest/rosin/")[rosin]], [🟡 poor widgets library], [], [✅ OK (with extra setup)], [✅ OK],
  [#link("https://docs.rs/rui/latest/rui/")[rui]], [🟡 poor widgets library], [], [❌ No], [❌ No],
  [#link("https://docs.rs/sdl3/latest/sdl3/")[SDL3]], [not a GUI framework], [], [], [],
  [#link("https://slint.dev/docs")[slint]], [✅ OK], [], [✅ OK], [✅ OK],
  [#link("https://tauri.app/")[Tauri]], [✅ OK], [WebView], [✅ OK], [✅ OK],
  [#link("https://docs.rs/tessera-ui/latest/tessera_ui/")[Tessera]], [no macOS support], [], [], [],
  [#link("https://docs.rs/tinyfiledialogs/latest/tinyfiledialogs/")[tinyfiledialogs]], [not a GUI framework], [], [], [],
  [#link("https://docs.rs/tk/latest/tk/")[Tk]], [🟡 API friction], [Tcl/Tk], [❌ No], [✅ OK],
  [#link("https://docs.rs/undoredo")[undoredo]], [not a GUI framework], [], [], [],
  [#link("https://docs.vizia.dev/vizia/")[Vizia]], [🟡 poor widgets library], [], [❌ crash], [✅ OK],
  [#link("https://docs.rs/webrender/latest/webrender/")[WebRender]], [not a GUI framework], [], [], [],
  [#link("https://microsoft.github.io/windows-docs-rs/")[Windows]], [😭 low-level API], [], [], [],
  [#link("https://github.com/microsoft/windows-rs/tree/master/crates/libs/reactor")[Windows Reactor]], [🟡 API friction], [Windows App SDK (bundled)], [🟡 text boxes only], [✅ OK],
  [#link("https://docs.rs/winsafe/latest/winsafe/")[WinSafe]], [✅ OK], [Windows only], [✅ OK], [✅ OK],
  [#link("https://docs.rs/wxdragon/latest/wxdragon/")[WxDragon]], [✅ OK], [wxWidgets (bundled)], [✅ OK], [✅ OK],
  [#link("https://docs.rs/xilem/latest/xilem/")[Xilem]], [✅ OK], [], [✅ OK], [🟡 CJK fonts unsupported],
  [#link("https://docs.rs/yew/")[Yew]], [web only], [], [], [],
))

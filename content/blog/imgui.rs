use imgui::*;
use imgui_wgpu::{Renderer, RendererConfig, Texture, TextureConfig};
use imgui_winit_support::WinitPlatform;
use pollster::block_on;
use std::{sync::Arc, time::Instant};
use wgpu::Extent3d;
use winit::{
    application::ApplicationHandler,
    dpi::LogicalSize,
    event::{Event, WindowEvent},
    event_loop::{ActiveEventLoop, ControlFlow, EventLoop},
    keyboard::{Key, NamedKey},
    window::Window,
};

struct ImguiState {
    context: imgui::Context,
    platform: WinitPlatform,
    renderer: Renderer,
    clear_color: wgpu::Color,
    last_frame: Instant,
    last_cursor: Option<MouseCursor>,
    text: String,
    qr: Option<TextureId>,
}

struct AppWindow {
    device: wgpu::Device,
    queue: wgpu::Queue,
    window: Arc<Window>,
    surface_desc: wgpu::SurfaceConfiguration,
    surface: wgpu::Surface<'static>,
    hidpi_factor: f64,
    imgui: Option<ImguiState>,
}

#[derive(Default)]
struct App {
    window: Option<AppWindow>,
}

impl AppWindow {
    fn setup_gpu(event_loop: &ActiveEventLoop) -> Self {
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::PRIMARY,
            ..wgpu::InstanceDescriptor::new_with_display_handle(Box::new(
                event_loop.owned_display_handle(),
            ))
        });

        let window = {
            let size = LogicalSize::new(1280.0, 720.0);

            let attributes = Window::default_attributes()
                .with_inner_size(size)
                .with_title("QR Code Generator");
            Arc::new(event_loop.create_window(attributes).unwrap())
        };

        let size = window.inner_size();
        let hidpi_factor = window.scale_factor();
        let surface = instance.create_surface(window.clone()).unwrap();

        let adapter = block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            compatible_surface: Some(&surface),
            force_fallback_adapter: false,
        }))
        .unwrap();

        let (device, queue) =
            block_on(adapter.request_device(&wgpu::DeviceDescriptor::default())).unwrap();

        // Set up swap chain
        let surface_desc = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: wgpu::TextureFormat::Bgra8UnormSrgb,
            width: size.width,
            height: size.height,
            present_mode: wgpu::PresentMode::Fifo,
            desired_maximum_frame_latency: 2,
            alpha_mode: wgpu::CompositeAlphaMode::Auto,
            view_formats: vec![wgpu::TextureFormat::Bgra8Unorm],
        };

        surface.configure(&device, &surface_desc);

        let imgui = None;
        Self {
            device,
            queue,
            window,
            surface_desc,
            surface,
            hidpi_factor,
            imgui,
        }
    }

    fn setup_imgui(&mut self) {
        let mut context = imgui::Context::create();
        let mut platform = imgui_winit_support::WinitPlatform::new(&mut context);
        platform.attach_window(
            context.io_mut(),
            &self.window,
            imgui_winit_support::HiDpiMode::Default,
        );
        context.set_ini_filename(None);

        let font_size = (13.0 * self.hidpi_factor) as f32;
        context.io_mut().font_global_scale = (1.0 / self.hidpi_factor) as f32;

        context.fonts().add_font(&[FontSource::DefaultFontData {
            config: Some(imgui::FontConfig {
                size_pixels: font_size,
                ..Default::default()
            }),
        }]);

        let clear_color = wgpu::Color {
            r: 0.1,
            g: 0.2,
            b: 0.3,
            a: 1.0,
        };

        let renderer_config = RendererConfig {
            texture_format: self.surface_desc.format,
            ..Default::default()
        };

        let renderer = Renderer::new(&mut context, &self.device, &self.queue, renderer_config);
        let last_frame = Instant::now();
        let last_cursor = None;

        self.imgui = Some(ImguiState {
            context,
            platform,
            renderer,
            clear_color,
            last_frame,
            last_cursor,
            text: String::new(),
            qr: None,
        })
    }

    fn new(event_loop: &ActiveEventLoop) -> Self {
        let mut window = Self::setup_gpu(event_loop);
        window.setup_imgui();
        window
    }
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        self.window = Some(AppWindow::new(event_loop));
    }

    fn window_event(
        &mut self,
        event_loop: &ActiveEventLoop,
        window_id: winit::window::WindowId,
        event: WindowEvent,
    ) {
        let window = self.window.as_mut().unwrap();
        let imgui = window.imgui.as_mut().unwrap();

        match &event {
            WindowEvent::Resized(size) => {
                window.surface_desc.width = size.width;
                window.surface_desc.height = size.height;
                window
                    .surface
                    .configure(&window.device, &window.surface_desc);
            }
            WindowEvent::ScaleFactorChanged { scale_factor, .. } => {
                window.hidpi_factor = *scale_factor;
                let font_size = (13.0 * window.hidpi_factor) as f32;
                imgui.context.fonts().clear();
                imgui
                    .context
                    .fonts()
                    .add_font(&[FontSource::DefaultFontData {
                        config: Some(imgui::FontConfig {
                            oversample_h: 1,
                            pixel_snap_h: true,
                            size_pixels: font_size,
                            ..Default::default()
                        }),
                    }]);
                imgui.renderer.reload_font_texture(
                    &mut imgui.context,
                    &window.device,
                    &window.queue,
                );
            }
            WindowEvent::CloseRequested => event_loop.exit(),
            WindowEvent::KeyboardInput { event, .. } => {
                if let Key::Named(NamedKey::Escape) = event.logical_key
                    && event.state.is_pressed()
                {
                    event_loop.exit();
                }
            }
            WindowEvent::RedrawRequested => {
                let now = Instant::now();
                imgui
                    .context
                    .io_mut()
                    .update_delta_time(now - imgui.last_frame);
                imgui.last_frame = now;

                let frame = match window.surface.get_current_texture() {
                    wgpu::CurrentSurfaceTexture::Success(frame) => frame,
                    wgpu::CurrentSurfaceTexture::Suboptimal(frame) => frame,
                    wgpu::CurrentSurfaceTexture::Timeout
                    | wgpu::CurrentSurfaceTexture::Occluded => return,
                    wgpu::CurrentSurfaceTexture::Outdated | wgpu::CurrentSurfaceTexture::Lost => {
                        window
                            .surface
                            .configure(&window.device, &window.surface_desc);
                        return;
                    }
                    other => {
                        eprintln!("get_current_texture error: {other:?}");
                        return;
                    }
                };
                imgui
                    .platform
                    .prepare_frame(imgui.context.io_mut(), &window.window)
                    .expect("Failed to prepare frame");
                let ui = imgui.context.frame();

                {
                    // Clone before the closure: `window` is already mutably
                    // borrowed via `imgui`, and Device/Queue are cheap Arc clones.
                    let device = window.device.clone();
                    let queue = window.queue.clone();
                    ui.window("QR Code Generator")
                        .size([300.0, 100.0], Condition::FirstUseEver)
                        .build(|| {
                            ui.text("Enter text to generate QR code:");
                            if ui.input_text("text", &mut imgui.text).build()
                                && let Ok(qr) = qr_encode(&imgui.text)
                            {
                                let image = qr.into_rgba8();
                                let (width, height) = image.dimensions();
                                let raw_data = image.into_raw();

                                let texture_config = TextureConfig {
                                    size: Extent3d {
                                        width,
                                        height,
                                        ..Default::default()
                                    },
                                    label: Some("qrcode"),
                                    format: Some(wgpu::TextureFormat::Rgba8Unorm),
                                    ..Default::default()
                                };

                                let texture = Texture::new(
                                    &device,
                                    &imgui.renderer,
                                    texture_config,
                                );

                                texture.write(&queue, &raw_data, width, height);
                                imgui.qr = Some(imgui.renderer.textures.insert(texture));
                            }
                            if let Some(qr_id) = imgui.qr {
                                Image::new(qr_id, [200.0, 200.0]).build(ui);
                            }
                        });
                }

                let mut encoder: wgpu::CommandEncoder = window
                    .device
                    .create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

                if imgui.last_cursor != ui.mouse_cursor() {
                    imgui.last_cursor = ui.mouse_cursor();
                    imgui.platform.prepare_render(ui, &window.window);
                }

                let view = frame
                    .texture
                    .create_view(&wgpu::TextureViewDescriptor::default());
                let mut rpass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: None,
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(imgui.clear_color),
                            store: wgpu::StoreOp::Store,
                        },
                        depth_slice: None,
                    })],
                    depth_stencil_attachment: None,
                    timestamp_writes: None,
                    occlusion_query_set: None,
                    multiview_mask: None,
                });

                imgui
                    .renderer
                    .render(
                        imgui.context.render(),
                        &window.queue,
                        &window.device,
                        &mut rpass,
                    )
                    .expect("Rendering failed");

                drop(rpass);

                window.queue.submit(Some(encoder.finish()));

                frame.present();
            }
            _ => (),
        }

        imgui.platform.handle_event::<()>(
            imgui.context.io_mut(),
            &window.window,
            &Event::WindowEvent { window_id, event },
        );
    }

    fn user_event(&mut self, _event_loop: &ActiveEventLoop, event: ()) {
        let window = self.window.as_mut().unwrap();
        let imgui = window.imgui.as_mut().unwrap();
        imgui.platform.handle_event::<()>(
            imgui.context.io_mut(),
            &window.window,
            &Event::UserEvent(event),
        );
    }

    fn device_event(
        &mut self,
        _event_loop: &ActiveEventLoop,
        device_id: winit::event::DeviceId,
        event: winit::event::DeviceEvent,
    ) {
        let window = self.window.as_mut().unwrap();
        let imgui = window.imgui.as_mut().unwrap();
        imgui.platform.handle_event::<()>(
            imgui.context.io_mut(),
            &window.window,
            &Event::DeviceEvent { device_id, event },
        );
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        let window = self.window.as_mut().unwrap();
        let imgui = window.imgui.as_mut().unwrap();
        window.window.request_redraw();
        imgui.platform.handle_event::<()>(
            imgui.context.io_mut(),
            &window.window,
            &Event::AboutToWait,
        );
    }
}

pub fn qr_encode(text: &str) -> anyhow::Result<image::DynamicImage> {
    let code = qrcode::QrCode::new(text.as_bytes())?;
    let img = code.render::<image::Luma<u8>>().build();
    Ok(img.into())
}

fn main() {
    env_logger::init();
    let event_loop = EventLoop::new().unwrap();
    event_loop.set_control_flow(ControlFlow::Poll);
    event_loop.run_app(&mut App::default()).unwrap();
}

require "gosu"
require "gosu_more_drawables"

class Flowtime
  class Window < Gosu::Window
    GAME_ROOT = File.expand_path(".", __dir__)
    def initialize(*args)
      super

      self.caption = "Flowtime"

      @timer = 0
      @paused = true
      @break = false

      @total_work_time = 0
      @total_break_time = 0

      @last_frame_time = Gosu.milliseconds

      @small_font = Gosu::Font.new(24, bold: true)
      @font = Gosu::Font.new(72, bold: true)

      @play_icon = Gosu::Image.new("#{GAME_ROOT}/media/right.png")
      @pause_icon = Gosu::Image.new("#{GAME_ROOT}/media/pause.png")
      @cycle_icon = Gosu::Image.new("#{GAME_ROOT}/media/fastForward.png")

      @break_complete_sound = Gosu::Sample.new("#{GAME_ROOT}/media/gentle_ding_oga_SpringSpring.ogg")

      @buttons = [
        {
          draw_via: method(:draw_pause),
          callback: -> { toggle_timer },
          radius: 36,
          color: 0xff_258e22,
          hover_color: 0xaa_258e22,
          x: width / 2 - 50,
          y: height / 2 + @font.height / 2
        },
        {
          draw_via: method(:draw_cycle),
          callback: -> { cycle_mode },
          radius: 36,
          color: 0xff_353535,
          hover_color: 0xaa_353535,
          x: width / 2 + 50,
          y: height / 2 + @font.height / 2
        }
      ]
    end

    def draw
      Gosu.draw_rect(0, 0, width, height, 0xff_aaaaaa)

      text_width = @small_font.text_width(@break ? "Chillin'" : "Focusing...")
      @small_font.draw_text(@break ? "Chillin'" : "Focusing...", width / 2 - text_width / 2 + 1, height / 2 - (@font.height + @font.height) + 1, 0, 1, 1, 0xaa_000000)
      @small_font.draw_text(@break ? "Chillin'" : "Focusing...", width / 2 - text_width / 2, height / 2 - (@font.height + @font.height), 0)

      text_width = @font.text_width(format_timer(@timer))
      @font.draw_text(format_timer(@timer), width / 2 - text_width / 2 + 1, height / 2 - @font.height + 1, 0, 1, 1, 0xaa_000000)
      @font.draw_text(format_timer(@timer), width / 2 - text_width / 2, height / 2 - @font.height, 0)

      @buttons.each do |button|
        button[:draw_via].call(button)
      end

      return unless Gosu.button_down?(Gosu::KB_TAB)

      @small_font.draw_text("Rest: #{format_timer(@total_break_time)}   Task: #{format_timer(@total_work_time)}", 11, height - @small_font.height + 1, 10, 1, 1, 0xaa_000000)
      @small_font.draw_text("Rest: #{format_timer(@total_break_time)}   Task: #{format_timer(@total_work_time)}", 10, height - @small_font.height, 10)
    end

    def draw_pause(hash)
      Gosu.draw_circle(
        hash[:x],
        hash[:y],
        hash[:radius],
        128,
        mouse_over_button?(hash) ? hash[:hover_color] : hash[:color]
      )

      icon = @paused ? @play_icon : @pause_icon
      icon.draw_rot(hash[:x], hash[:y], 0, 0, 0.5, 0.5, 0.5, 0.5)
    end

    def draw_cycle(hash)
      Gosu.draw_circle(
        hash[:x],
        hash[:y],
        hash[:radius],
        128,
        mouse_over_button?(hash) ? hash[:hover_color] : hash[:color]
      )

      @cycle_icon.draw_rot(hash[:x], hash[:y], 0, 0, 0.5, 0.5, 0.5, 0.5)
    end

    def update
      dt = Gosu.milliseconds - @last_frame_time
      @last_frame_time = Gosu.milliseconds

      return if @paused

      if @break
        @timer -= dt
        @total_break_time += dt

        if @timer.negative? || @timer.round.zero?
          @paused = true
          @timer = 0

          @break_complete_sound.play
        end
      else
        @timer += dt
        @total_work_time += dt
      end
    end

    def mouse_over_button?(hash)
      Gosu.distance(mouse_x, mouse_y, hash[:x], hash[:y]) < hash[:radius]
    end

    def button_down(id)
      case id
      when Gosu::MS_LEFT
        btn = @buttons.find { |b| mouse_over_button?(b) }
        btn[:callback].call if btn
      end
    end

    def toggle_timer
      @paused = !@paused
      @paused = true if @break && @timer <= 0
    end

    def cycle_mode
      @paused = true

      if @break
        @break = false

        @timer = 0
      else
        @break = true

        @timer = (@timer / 1000.0 / 5.0) * 1000.0
      end
    end

    def format_timer(timer)
      minutes = timer / 1000.0 / 60.0
      seconds = timer / 1000.0 % 59.99999999

      "#{format("%02d", minutes)}:#{format("%02d", seconds)}"
    end
  end
end

Flowtime::Window.new(500, 350, false).show

require '/Users/nickj/.rbenv/versions/2.1.7/lib/ruby/gems/2.1.0/bundler/gems/RxRuby-e493b321a7a9/lib/rx'
require 'ostruct'

def random_word
  File.readlines('words.txt').sample.chomp.upcase
end

def view(state, hide_letters: true)
  letters_to_display = state.word.chars

  if hide_letters
    letters_to_display = state.word.chars
      .map { |letter| state.guesses.include?(letter) ? letter : '_' }
  end

  <<-GAME
Lives left: #{state.lives}
Letters guessed: #{state.guesses.join(', ')}

#{letters_to_display.join(' ')}
  GAME
end

def perform_guess(state, guess)
  guess_was_successful = state.word.chars.include? guess

  if guess_was_successful
    lives = state.lives
  else
    lives = state.lives - 1
  end

  OpenStruct.new(
    lives: lives,
    word: state.word,
    guesses: state.guesses.concat([guess])
  )
end

def valid_guess?(guess)
  guess.match(/^[A-Z]$/)
end

def game_won?(state)
  state.word.chars.all? { |letter| state.guesses.include? letter }
end

def game_over?(state)
  state.lives == 0
end

def play_game
  guesses = RX::Observable.from($stdin)

  initial_state = OpenStruct.new(
    lives: 7,
    word: random_word,
    guesses: []
  )

  state = guesses
    .map { |guess| guess.upcase.chomp }
    .select { |guess| valid_guess?(guess) }
    .start_with(initial_state)
    .scan { |state, guess| perform_guess(state, guess) }

  state.subscribe do |state|
    if game_won?(state)
      puts "You win!"
      exit
    end

    if game_over?(state)
      puts view(state, hide_letters: false)
      puts "You lose!"
      exit
    end

    puts view(state)
    puts "Guess a letter:"
  end
end

play_game

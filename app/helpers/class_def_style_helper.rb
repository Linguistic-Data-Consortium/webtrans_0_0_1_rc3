module ClassDefStyleHelper

  def set_class_def_css(cd, type)
    case type
    when 'manifest_text'
      cd.css = manifest_text
      cd.save
    when 'audio'
      cd.css = audio
      cd.save
    when 'othermedia'
      cd.css = one_column_media
      cd.save
    when 'text'
      cd.css = text
      cd.save
    end
  end

  private

  def audio
    """
.DefaultListItem {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: minmax(min-content, max-content);
  padding: 2em;
}

.ExerciseTextLabel {
  grid-row: 1 / span 1;
  grid-column: 1 / span 1;
  padding: 1em 0;
}

.ListAudio {
  grid-row: 2 / span 1;
  grid-column: 1 / span 2;
}

.Language, .LangAutocomplete {
  display: flex;
  justify-content: flex-end;
  grid-row: 1 / span 1;
  grid-column: 2 / span 1;
}

.Language .row-fluid, .LangAutocomplete .row-fluid {
  display: flex;
}

.Language .row-fluid  *, .LangAutocomplete .row-fluid  *{
  padding-left: .5em;
}

.InputTextLabel, .ContextTextLabel, .PrimaryTextLabel, .SecondaryTextLabel {
  display: flex;
  justify-content: flex-start;
  grid-column: 1 / span 2;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}

.InputTextLabel *, .ContextTextLabel *, .PrimaryTextLabel *, .SecondaryTextLabel * {
  padding-right: .5em;
}

.InputTextLabel, .PrimaryTextLabel {
  grid-row: 3 / span 1;
}

.ContextTextLabel, .SecondaryTextLabel {
  grid-row: 4 / span 1;
}

.Entry {
  padding: 1em 0;
  grid-row: 5 / span 1;
  grid-column: 1 / span 2;
}

.ButtonsWrapper {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  grid-row: 6 / span 1;
  grid-column: 1 / span 2;
}
    """
  end

  def manifest_text
    """
.DefaultListItem {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: minmax(min-content, max-content);
  padding: 2em;
}

.ExerciseTextLabel {
  grid-row: 1 / span 1;
  grid-column: 1 / span 1;
  padding: 1em 0;
}

.Language, .LangAutocomplete {
  display: flex;
  justify-content: flex-end;
  grid-row: 1 / span 1;
  grid-column: 2 / span 1;
}

.Language .row-fluid, .LangAutocomplete .row-fluid {
  display: flex;
}

.Language .row-fluid  *, .LangAutocomplete .row-fluid  *{
  padding-left: .5em;
}

.InputTextLabel, .ContextTextLabel, .PrimaryTextLabel, .SecondaryTextLabel {
  display: flex;
  justify-content: flex-start;
  grid-column: 1 / span 2;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}

.InputTextLabel *, .ContextTextLabel *, .PrimaryTextLabel *, .SecondaryTextLabel * {
  padding-right: .5em;
}

.InputTextLabel, .PrimaryTextLabel {
  grid-row: 2 / span 1;
}

.ContextTextLabel, .SecondaryTextLabel {
  grid-row: 3 / span 1;
}

.Entry {
  padding: 1em 0;
  grid-row: 4 / span 1;
  grid-column: 1 / span 2;
}

.ButtonsWrapper {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  grid-row: 5 / span 1;
  grid-column: 1 / span 2;
}
"""
  end

  def othermedia
    """
.DefaultListItem {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: minmax(min-content, max-content);
  grid-gap: .5em 1em;
  padding: 2em;
}

.ExerciseTextLabel {
  grid-row: 1 / span 1;
  grid-column: 1 / span 2;
}

.Language, .LangAutocomplete {
  display: flex;
  justify-content: flex-end;
  grid-row: 2 / span 1;
  grid-column: 2 / span 1;
}

.Language .row-fluid, .LangAutocomplete .row-fluid {
  display: flex;
}

.Language .row-fluid  *, .LangAutocomplete .row-fluid  *{
  padding-left: .5em;
}

.ListMedia {
  grid-column:  1 / span 1;
  grid-row: 2 / span 5;
}

@media only screen and (min-width: 950px) {
  .ListMedia {
    width: 550px;
  }
}

.AudioResponse {
  grid-column: 2 / span 1;
  grid-row: 5 / span 1;
}

.Entry {
  padding: 1em 0;
  grid-row: 6 / span 1;
  grid-column: 2 / span 1;
}

.ExerciseTextLabel {
  display: flex;
  justify-content: flex-start;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}

.InputTextLabel, .ContextTextLabel, .PrimaryTextLabel, .SecondaryTextLabel {
  display: flex;
  justify-content: flex-start;
  grid-column: 2 / span 1;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}
.InputTextLabel *, .ContextTextLabel *, .PrimaryTextLabel *, .SecondaryTextLabel * {
  padding-right: .5em;
}

.InputTextLabel, .PrimaryTextLabel {
  grid-row: 3 / span 1;
}

.ContextTextLabel, .SecondaryTextLabel {
  grid-row: 4 / span 1;
}

.ButtonsWrapper {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  grid-row: 7 / span 1;
  grid-column: 1 / span 2;
}

.Judgment, .PromptID {
  display: none;
}
"""
  end

  def text
    """
.DefaultListItem {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: minmax(min-content, max-content);
  grid-gap: .5em 1em;
  padding: 2em;
}

.ExerciseTextLabel {
  grid-row: 1 / span 1;
  grid-column: 1 / span 2;
}

.Language, .LangAutocomplete {
  display: flex;
  justify-content: flex-end;
  grid-row: 2 / span 1;
  grid-column: 2 / span 1;
}

.Language .row-fluid, .LangAutocomplete .row-fluid {
  display: flex;
}

.Language .row-fluid  *, .LangAutocomplete .row-fluid  *{
  padding-left: .5em;
}

.ListText {
  grid-column:  1 / span 1;
  grid-row: 2 / span 5;
  max-height: 25em;
  overflow: auto;
}

@media only screen and (min-width: 950px) {
  .ListMedia {
    width: 550px;
  }
}

.AudioResponse {
  grid-column: 2 / span 1;
  grid-row: 5 / span 1;
}

.Entry {
  padding: 1em 0;
  grid-row: 6 / span 1;
  grid-column: 2 / span 1;
}

.ExerciseTextLabel {
  display: flex;
  justify-content: flex-start;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}

.InputTextLabel, .ContextTextLabel, .PrimaryTextLabel, .SecondaryTextLabel {
  display: flex;
  justify-content: flex-start;
  grid-column: 2 / span 1;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}
.InputTextLabel *, .ContextTextLabel *, .PrimaryTextLabel *, .SecondaryTextLabel * {
  padding-right: .5em;
}

.InputTextLabel, .PrimaryTextLabel {
  grid-row: 3 / span 1;
}

.ContextTextLabel, .SecondaryTextLabel {
  grid-row: 4 / span 1;
}

.ButtonsWrapper {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  grid-row: 7 / span 1;
  grid-column: 1 / span 2;
}

.Judgment, .PromptID {
  display: none;
}
"""
  end

  def one_column_text
    """
.DefaultListItem {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: minmax(min-content, max-content);
  grid-gap: .5em 1em;
  padding: 2em;
}

.ExerciseTextLabel {
  grid-row: 1 / span 1;
  grid-column: 1 / span 2;
}

.Language, .LangAutocomplete {
  display: flex;
  justify-content: flex-end;
  grid-row: 2 / span 1;
  grid-column: 2 / span 1;
}

.Language .row-fluid, .LangAutocomplete .row-fluid {
  display: flex;
}

.Language .row-fluid  *, .LangAutocomplete .row-fluid  *{
  padding-left: .5em;
}

.ListText {
  grid-column:  1 / span 2;
  grid-row: 3 / span 4;
  max-height: 25em;
  overflow: auto;
}

@media only screen and (min-width: 950px) {
  .ListMedia {
    width: 550px;
  }
}

.AudioResponse {
  grid-column: 1 / span 2;
  grid-row: 10 / span 1;
}

.Entry {
  padding: 1em 0;
  grid-row: 7 / span 1;
  grid-column: 2 / span 1;
}

.ExerciseTextLabel {
  display: flex;
  justify-content: flex-start;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}

.InputTextLabel, .ContextTextLabel, .PrimaryTextLabel, .SecondaryTextLabel {
  display: flex;
  justify-content: flex-start;
  grid-column: 2 / span 1;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}
.InputTextLabel *, .ContextTextLabel *, .PrimaryTextLabel *, .SecondaryTextLabel * {
  padding-right: .5em;
}

.InputTextLabel, .PrimaryTextLabel {
  grid-row: 8 / span 1;
}

.ContextTextLabel, .SecondaryTextLabel {
  grid-row: 9 / span 1;
}

.ButtonsWrapper {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  grid-row: 11 / span 1;
  grid-column: 1 / span 2;
}

.Judgment, .PromptID {
  display: none;
}
"""
  end

  def one_column_media
    """
.DefaultListItem {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: minmax(min-content, max-content);
  grid-gap: .5em 1em;
  padding: 2em;
}

.ExerciseTextLabel {
  grid-row: 1 / span 1;
  grid-column: 1 / span 2;
}

.Language, .LangAutocomplete {
  display: flex;
  justify-content: flex-end;
  grid-row: 2 / span 1;
  grid-column: 2 / span 1;
}

.Language .row-fluid, .LangAutocomplete .row-fluid {
  display: flex;
}

.Language .row-fluid  *, .LangAutocomplete .row-fluid  *{
  padding-left: .5em;
}

.ListText, .ListMedia {
  grid-column:  1 / span 2;
  grid-row: 3 / span 4;
  overflow: auto;
  width: 100%;
}

.ListMedia video, .ListMedia img {
  max-width: 100%;
}

.AudioResponse {
  grid-column: 1 / span 2;
  grid-row: 10 / span 1;
}

.Entry {
  padding: 1em 0;
  grid-row: 7 / span 1;
  grid-column: 2 / span 1;
}

.ExerciseTextLabel {
  display: flex;
  justify-content: flex-start;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}

.InputTextLabel, .ContextTextLabel, .PrimaryTextLabel, .SecondaryTextLabel {
  display: flex;
  justify-content: flex-start;
  grid-column: 2 / span 1;
  padding: 1em 0;
  border-bottom: 1px solid rgb(207, 207, 207);
}
.InputTextLabel *, .ContextTextLabel *, .PrimaryTextLabel *, .SecondaryTextLabel * {
  padding-right: .5em;
}

.InputTextLabel, .PrimaryTextLabel {
  grid-row: 8 / span 1;
}

.ContextTextLabel, .SecondaryTextLabel {
  grid-row: 9 / span 1;
}

.ButtonsWrapper {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  grid-row: 11 / span 1;
  grid-column: 1 / span 2;
}

.Judgment, .PromptID {
  display: none;
}
"""
  end

end
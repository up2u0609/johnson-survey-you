require File.expand_path(File.dirname(__FILE__) + '/shams')

Surveyor::Survey.blueprint do
  title         {"Simple survey"}
  description   {"A simple survey for testing"}
  access_code   { Sham.big_number }
  active_at     {Time.now}
  inactive_at   {}
  css_url       {}
end

#Factory.sequence(:survey_section_display_order){|n| n }

Surveyor::SurveySection.blueprint do
  survey # s.survey_id                 {}
  title                     {"Demographics"}
  description               {"Asking you about your personal data"}
  display_order             { Sham.small_number }
  reference_identifier      {"demographics"}
  data_export_identifier    {"demographics"}
end

Surveyor::Question.blueprint do
  survey_section  # s.survey_section_id       {}
  question_group
  text                    {"What is your favorite color?"}
  short_text              {"favorite_color"}
  help_text               {"just write it in the box"}
  pick                    {:none}
  reference_identifier    { "q_#{Sham.small_number}"}
  data_export_identifier  {}
  common_namespace        {}
  common_identifier       {}
  display_order           {Sham.small_number}
  display_type            {} # nil is default
  is_mandatory            {false}
  display_width           {}
  correct_answer_id       {nil}
end

Surveyor::QuestionGroup.blueprint do 
  text                    {"Describe your family"}
  help_text               {}
  reference_identifier    { "g_#{Sham.small_number}"}
  data_export_identifier  {}
  common_namespace        {}
  common_identifier       {}
  display_type            {}
  custom_class            {}
  custom_renderer         {}
end


Surveyor::Answer.blueprint do
  question  # a.question_id               {}
  text                      {"My favorite color is clear"}
  short_text                {"clear"}
  help_text                 {"Clear is the absense of color"}
  weight                    {}
  response_class            {"String"}
  reference_identifier      {}
  data_export_identifier    {}
  common_namespace          {}
  common_identifier         {}
  display_order             { Sham.small_number }
  is_exclusive              {}
  display_type              "default"
  display_length            {}
  custom_class              {}
  custom_renderer           {}
end

Surveyor::Dependency.blueprint do
  # the dependent question
  question # d.question_id       {}
  question_group
  rule              {"A"}
end

Surveyor::DependencyCondition.blueprint do
  dependency # d.dependency_id    {}
  rule_key          {"A"}
  # the conditional question
  operator          {"=="}
  datetime_value    {}
  integer_value     {}
  float_value       {}
  unit              {}
  text_value        {}
  string_value      {}
  response_other    {}
end

Surveyor::ResponseSet.blueprint do
  user_id         {}
  survey # r.survey_id       {}
  access_code     {Surveyor::Common.make_tiny_code}
  started_at      {Time.now}
  completed_at    {}
end

Surveyor::Response.blueprint do
  response_set # r.response_set_id   {}
  survey_section_id {}
  question       {}
  answer         {}
  datetime_value    {}
  integer_value     {}
  float_value       {}
  unit              {}
  text_value        {}
  string_value      {}
  response_other    {}
  response_group    {}
end

Surveyor::Validation.blueprint do
  answer # v.answer_id
  rule              {"A"}
  message           {}
end

Surveyor::ValidationCondition.blueprint do
  validation # v.validation_id     {}
  rule_key          {"A"}
  question_id       {}
  operator          {"=="}
  answer_id         {}
  datetime_value    {}
  integer_value     {}
  float_value       {}
  unit              {}
  text_value        {}
  string_value      {}
  response_other    {}
  regexp            {}
end

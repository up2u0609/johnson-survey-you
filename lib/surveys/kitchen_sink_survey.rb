survey "请给第一个screencast来点反馈" do

  section "请给第一个screencast来点反馈" do
    # A label is a question that accepts no answers
    label "对于第一期的screencast,麻烦您打个分(每项满分5分)："

    # A basic question with radio buttons
    q_1 "声音怎么样", :pick => :one
    a "渣"
    a "烂"
    a "凑合"
    a "还行"
    a "不错"
    q_1_1 "我有点其他意见"
    a "说道说道：" , :text

    # A basic question with checkboxes
    # "question" and "answer" may be abbreviated as "q" and "a"
    q_2 "画质怎么样", :pick => :one
    a "渣"
    a "烂"
    a "凑合"
    a "还行"
    a "不错"

    q_2_1 "我有点其他意见"
    a "说道说道：" , :text

    q_3 "内容怎么样", :pick => :one
    a "渣"
    a "烂"
    a "凑合"
    a "还行"
    a "不错"

    q_3_1 "我有点其他意见"
    a "说道说道：" , :text

    q_3 "讲解怎么样", :pick => :one
    a "渣"
    a "烂"
    a "凑合"
    a "还行"
    a "不错"

    q_4_1 "我有点其他意见"
    a "说道说道：" , :text

    q_4 "其他爽和不爽"
    a_1 "您随便说：", :text

    q_5 "另外,您近期最关注或希望了解的ruby社区话题？"
    a_1 "您随便聊聊？", :text

    q_6 "2.您目前工作中最需要的技术是？"
    a_1 "您随便聊聊？", :text

    q_7 "3.您在目前的工作中遇到了哪些阻碍？都是怎么解决的？"
    a_1 "您随便聊聊？", :text
  end
end


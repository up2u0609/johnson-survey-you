Sham.define do
  name{  Forgery(:lorem_ipsum).words(6 , :random => true)  }
  username{  Forgery(:name).full_name  }
  password{  Forgery(:basic).password(:at_least => 6, :at_most => 10)  }
  title{  Forgery(:lorem_ipsum).words(6 , :random => true)  }
  email{  Forgery(:internet).email_address  }
  description(:unique => false ) {  Forgery::LoremIpsum.sentence(:random => true)  }
  content(:unique => false ) {  Forgery::LoremIpsum.sentence(:random => true)  }
  small_number(:unique => false){  Forgery(:basic).number(:at_most => 6 , :at_least => 1)  }
  big_number(:unique => true){  Forgery(:basic).number(:at_most => 1000 , :at_least => 1)  }
  detector{  Forgery(:lorem_ipsum).word(:random => true).classify  }
  zipcode{  Forgery(:address).zip  }
  address{  Forgery(:address).street_address   }
  birthdate{  Forgery(:date).date  }
  city{  Forgery(:address).city  }
  gender(:unique => false){  Forgery(:personal).gender  }
  locale(:unique => false){"fr"}
  
end


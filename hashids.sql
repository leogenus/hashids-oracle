CREATE OR REPLACE PACKAGE hashids AS

  MAX_NUMBER constant NUMBER := 9007199254740992;

  DEFAULT_ALPHABET constant varchar2(32767) := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  DEFAULT_SEPS constant varchar2(32767) := 'cfhistuCFHISTU';
  DEFAULT_SALT constant varchar2(32767) := '';

  DEFAULT_MIN_HASH_LENGTH constant NUMBER := 0;
  MIN_ALPHABET_LENGTH constant NUMBER := 16;
  GUARD_DIV constant NUMBER := 12;
  SEP_DIV constant NUMBER := 3.5;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION encode(p_number in number)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION encode(p_numbers in NUM_ARRAY)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION encode_(p_alphabet in varchar2, p_salt in varchar2, p_min_hash_length in number, p_numbers in NUM_ARRAY)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION consistent_shuffle(p_alphabet in varchar2, p_salt in varchar2)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION hash_function(p_input in number, p_alphabet in varchar2)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION generate_seps(p_alphabet in varchar2, p_salt in varchar2)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION generate_guards(p_alphabet in varchar2, p_seps in varchar2)
    RETURN VARCHAR2;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION char_to_byte(p_string in varchar2, p_index in number)
    RETURN number;


  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION swap_char(p_string in varchar2, p_first in number, p_second in number )
    RETURN varchar2;

  /**
  * Get Hashid algorithm version.
  *
  * @return Hashids algorithm version implemented.
  */
  FUNCTION GET_VERSION
    RETURN VARCHAR2;

END hashids;
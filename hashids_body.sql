CREATE OR REPLACE PACKAGE BODY hashids AS

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION encode(p_number in number)
    RETURN VARCHAR2 as
  begin
    return encode(NUM_ARRAY(p_number));
  end;

  /**
  * Encode the numbers to the varchar type.
  * yo can use this like :
  *
  * ` select hashids.encode(num_array(1,2)) from dual; `
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION encode(p_numbers in NUM_ARRAY)
    RETURN VARCHAR2 is
    l_total NUMBER;
    l_number NUMBER;
    begin
      l_total := p_numbers.COUNT;
      if l_total = 0 then
       return '';
      end if;

      FOR i in 1 .. l_total LOOP
        begin
          l_number := p_numbers(i);
          if l_number < 0 then
            return '';
          end if;

          if l_number > MAX_NUMBER then
            RAISE_APPLICATION_ERROR(-20001, 'number can not be greater than ' || MAX_NUMBER);
          end if;
        end;
      END LOOP;

      return encode_(DEFAULT_ALPHABET, DEFAULT_SALT, DEFAULT_MIN_HASH_LENGTH, p_numbers);
    end;

  /**
  * Encode the numbers to the varchar type.
  * yo can use this like :
  *
  * ` select hashids.encode(num_array(1,2)) from dual; `
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION encode_(p_alphabet in varchar2, p_salt in varchar2, p_min_hash_length in number, p_numbers in NUM_ARRAY)
    RETURN VARCHAR2 is
    l_total NUMBER;
    l_number NUMBER;
    l_number_hash_int NUMBER := 0;
    l_ret varchar2(32767);
    l_num number;
    l_seps_index number;
    l_guard_index number;
    l_buffer varchar2(32767);
    l_ret_str_b varchar2(32767);
    l_alphabet varchar2(32767);
    l_last varchar2(32767);
    l_seps varchar2(32767);
    l_ret_str varchar2(32767);
    l_guards varchar2(32767);
    l_guard character;
    l_half_len number;
    l_excess number;
    l_start_pos number;
  begin
    l_alphabet := p_alphabet;
    l_total := p_numbers.COUNT;
    if l_total = 0 then
      return '';
    end if;

    FOR i in 1 .. l_total
      LOOP
        l_number_hash_int := l_number_hash_int + mod(p_numbers(i), (i + 100 - 1));
      end loop;

    l_ret := SUBSTR(l_alphabet, mod(l_number_hash_int, length(l_alphabet)), 1);

    l_ret_str_b := l_ret;

    l_seps := generate_seps(l_alphabet, p_salt);

    FOR i in 1 .. l_total
      LOOP
        begin
          l_num := p_numbers(i);
          l_buffer := l_ret || p_salt || l_alphabet;
          l_alphabet := consistent_shuffle(l_alphabet, substr(l_buffer, 1, length(l_alphabet)));
          l_last := hash_function(l_num, l_alphabet);

          l_ret_str_b := l_ret_str_b || l_last;

          if i + 1 < p_numbers.COUNT then
            if length(l_last) > 0 then
              l_num := mod(l_num, char_to_byte(l_last, 1) + i - 1);
              l_seps_index := mod(l_num, length(l_seps));
            else
              l_seps_index := 0;
            end if;
            l_ret_str_b := l_ret_str_b || substr(l_seps, l_seps_index + 1, 1);
          end if;
        end;
      end loop;

    l_ret_str := l_ret_str_b;
    l_guards := generate_guards(l_alphabet, l_seps);

    if length(l_ret_str) < p_min_hash_length then
      l_guard_index := (l_number_hash_int + mod(char_to_byte(l_last, 1), length(l_guards)));
      l_guard := substr(l_guards, l_guard_index, 1);
      l_ret_str := l_guard || l_ret_str;

      if length(l_ret_str) < p_min_hash_length then
        l_guard_index := (l_number_hash_int + mod(char_to_byte(l_last, 3), length(l_guards)));
        l_guard := substr(l_guards, l_guard_index, 1);
        l_ret_str := l_ret_str || l_guard;
      end if;
    end if;

    l_half_len := length(l_alphabet) / 2;
    WHILE length(l_ret_str) < p_min_hash_length
      LOOP
        begin
          l_alphabet := consistent_shuffle(l_alphabet, l_alphabet);
          l_ret_str :=
                substr(l_alphabet, l_half_len, length(l_alphabet)) || l_ret_str || substr(l_alphabet, 1, l_half_len);
          l_excess := length(l_ret_str) - p_min_hash_length;

          if l_excess > 0 then
            l_start_pos := l_excess / 2;
            l_ret_str := substr(l_ret_str, l_start_pos + 1, l_start_pos + p_min_hash_length + 1);
          end if;
        end;
      END LOOP;

    return l_ret_str;
  end;

  /**
   * Encode the numbers to the varchar type.
   *
   * @return encoded hash code of numbers.
   */
  FUNCTION char_to_byte(p_string in varchar2, p_index in number)
    RETURN number as
    begin
      return TO_NUMBER(rawtohex(SUBSTR(p_string, p_index, 1)), 'XXXX');
    end;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION consistent_shuffle(p_alphabet in varchar2, p_salt in varchar2)
    RETURN VARCHAR2 is
    l_asc_val number;
    l_j number;
    l_v number := 0;
    l_p number := 0;
    l_salt_len number;
    l_tmp_arr varchar2(32767);
    begin
      l_tmp_arr := p_alphabet;
      l_salt_len := length(p_salt);
      if l_salt_len <= 0 then
        return p_alphabet;
      end if;

      FOR i IN REVERSE 1..length(l_tmp_arr)
        LOOP
          begin
            l_v := mod(l_v, l_salt_len);
            l_asc_val := char_to_byte(p_salt,l_v);
            l_p := l_p + l_asc_val;
            l_j := mod((l_asc_val + l_v + l_p), i - 1);
            l_tmp_arr := swap_char(l_tmp_arr, l_j, i);
          end;
        END LOOP;

    return l_tmp_arr;
    end;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION hash_function(p_input in number, p_alphabet in varchar2)
    RETURN VARCHAR2  is
    l_hash varchar2(32767);
    l_alphabet_len number;
    l_input DECIMAL;
    l_index number;
  begin
    l_alphabet_len := length(p_alphabet);
    l_input := p_input;

    LOOP
      l_index := mod(to_number(l_input), l_alphabet_len);

      if (l_index >= 0 and l_index < l_alphabet_len) then
        l_hash := substr(p_alphabet, l_index, 1) || + l_hash;
      end if;

      l_input := l_input / l_alphabet_len;
      EXIT when l_input > 0;
    END LOOP;

    return l_hash;
  end;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return encoded hash code of numbers.
  */
  FUNCTION generate_seps(p_alphabet in varchar2, p_salt in varchar2)
    RETURN VARCHAR2  as
    l_seps varchar2(32767);
    l_alphabet varchar2(32767);
    l_seps_len number;
    l_j number;
  begin
    l_seps := DEFAULT_SEPS;
    l_alphabet := p_alphabet;
    l_seps_len := length(l_seps);
    FOR i in 1 .. l_seps_len
      LOOP
        l_j := INSTR(l_alphabet, substr(l_seps, i, 1), 1);

        if l_j = -1 then
          l_seps := substr(l_seps, 1, i) || ' ' || substr(l_seps, i + 1);
        else
          l_alphabet := substr(l_seps, 1, l_j) || ' ' || substr(l_seps, l_j + 1);
        end if;
      end loop;
    return  consistent_shuffle(l_seps, p_salt);
  end;

  /**
  * Encode the numbers to the varchar type.
  *
  * @return generate_guards.
  */
  FUNCTION generate_guards(p_alphabet in varchar2, p_seps in varchar2)
    RETURN VARCHAR2  as
    l_guards varchar2(32767);
    l_seps varchar2(32767);
    l_alphabet varchar2(32767);
    l_guard_count number;
    l_alphabet_len number;
  begin
    l_alphabet_len := length(p_alphabet);
    l_guard_count := CEIL( l_alphabet_len / GUARD_DIV);

    if l_alphabet_len < 3 then
      l_guards := substr(p_seps, 1, l_guard_count);
      l_seps := substr(l_seps, l_guard_count);
    else
      l_guards := substr(p_seps, 1, l_guard_count);
      l_alphabet := substr(l_seps, l_guard_count);
    end if;

    return l_alphabet;
  end;

  /**
  * Get Hashid algorithm version.
  *
  * @return Hashids algorithm version implemented.
  */
  FUNCTION swap_char(p_string in varchar2, p_first in number, p_second in number )
    RETURN VARCHAR2 is
    l_first number := p_first;
    l_second number := p_second;
    l_cut1 varchar2(32767);
    l_cut2 varchar2(32767);
    l_cut3 varchar2(32767);
    l_cut4 varchar2(32767);
    l_cut5 varchar2(32767);
  begin
    if l_first = l_second then
      return p_string;
    end if;

    if l_first > l_second then
      l_first := p_second;
      l_second := p_first;
    end if;

    l_cut1 := substr(p_string, 1, l_first - 1);
    l_cut2 := substr(p_string, l_first, 1);
    l_cut3 := substr(p_string, l_first+1, l_second - l_first - 1);
    l_cut4 := substr(p_string, l_second, 1);
    l_cut5 := substr(p_string, l_second+1);

    return l_cut1 || l_cut4 || l_cut3 || l_cut2 || l_cut5;
  end;

  /**
  * Get Hashid algorithm version.
  *
  * @return Hashids algorithm version implemented.
  */
  FUNCTION GET_VERSION
    RETURN VARCHAR2 as
    begin
      return '1.0.0';
    end;

END hashids;
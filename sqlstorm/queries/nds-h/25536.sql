
WITH part_details AS (
    SELECT 
        p_name, 
        LENGTH(p_name) AS name_length, 
        UPPER(p_name) AS upper_name, 
        LOWER(p_name) AS lower_name, 
        SUBSTRING(p_name, 1, 10) AS name_substring, 
        p_retailprice, 
        p_comment, 
        CONCAT(p_name, ' - ', p_comment) AS full_description,
        p_partkey
    FROM part
), supplier_info AS (
    SELECT 
        s_name, 
        CONCAT(s_name, ' - ', s_address) AS supplier_address_info, 
        s_acctbal, 
        s_suppkey
    FROM supplier
), enriched_data AS (
    SELECT 
        pd.p_name, 
        pd.name_length, 
        pd.upper_name, 
        pd.lower_name, 
        pd.name_substring, 
        pd.p_retailprice, 
        pd.p_comment, 
        pd.full_description, 
        si.supplier_address_info, 
        si.s_acctbal
    FROM part_details pd
    JOIN partsupp ps ON ps.ps_partkey = pd.p_partkey
    JOIN supplier_info si ON si.s_suppkey = ps.ps_suppkey
)

SELECT 
    ed.p_name, 
    ed.name_length, 
    ed.upper_name, 
    ed.lower_name, 
    ed.name_substring, 
    ed.p_retailprice, 
    ed.p_comment, 
    ed.full_description, 
    ed.supplier_address_info,
    ed.s_acctbal
FROM enriched_data ed
WHERE ed.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY ed.name_length DESC, ed.p_retailprice DESC
LIMIT 100;

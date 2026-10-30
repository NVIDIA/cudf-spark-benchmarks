WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Type: ', p.p_type) AS combined_info,
        LENGTH(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Type: ', p.p_type)) AS length_of_combined_info,
        UPPER(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Type: ', p.p_type)) AS upper_combined_info,
        LENGTH(REPLACE(s.s_comment, ' ', '')) AS length_without_spaces,
        REPLACE(s.s_comment, ' ', '_') AS comment_with_underscores
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 10 
        AND s.s_acctbal > 1000.00
)
SELECT 
    part_name,
    supplier_name,
    combined_info,
    length_of_combined_info,
    upper_combined_info,
    length_without_spaces,
    comment_with_underscores
FROM 
    StringProcessing
ORDER BY 
    length_of_combined_info DESC;

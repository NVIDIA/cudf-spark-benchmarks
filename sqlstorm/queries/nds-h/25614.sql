
WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available_quantity,
           SUBSTRING(p.p_name, 1, 10) AS short_name,
           LOWER(REPLACE(p.p_comment, ' ', '_')) AS modified_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_comment
),
FilteredParts AS (
    SELECT rp.p_partkey, 
           rp.p_name,
           rp.supplier_count,
           rp.total_available_quantity,
           rp.short_name,
           rp.modified_comment
    FROM RankedParts rp
    WHERE rp.supplier_count > 5 AND rp.total_available_quantity > 1000
)
SELECT fp.p_partkey, 
       fp.p_name, 
       fp.supplier_count,
       fp.total_available_quantity,
       UPPER(fp.short_name) AS upper_short_name,
       LENGTH(fp.modified_comment) AS comment_length
FROM FilteredParts fp
ORDER BY fp.total_available_quantity DESC, fp.p_name ASC;

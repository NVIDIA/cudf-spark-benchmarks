WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           LENGTH(p.p_name) AS name_length, 
           SUBSTRING(p.p_name, 1, 10) AS short_name, 
           REPLACE(p.p_comment, 'good', 'excellent') AS updated_comment
    FROM part p
    WHERE p.p_retailprice > 100.00
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_availqty) AS total_available_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT rp.short_name, 
       rp.name_length, 
       sd.total_parts, 
       sd.total_available_qty
FROM RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey = (SELECT MIN(ps.ps_partkey) FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%Supplier%'))
ORDER BY rp.name_length DESC, sd.total_available_qty DESC
LIMIT 10;

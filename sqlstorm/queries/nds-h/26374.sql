WITH supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty,
        CONCAT(s.s_name, ', ', p.p_name, ' (', p.p_brand, ')') AS supplier_part_desc
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    supplier_part_desc,
    s_acctbal,
    SUM(ps_availqty) AS total_availqty,
    AVG(p_retailprice) AS average_retailprice
FROM supplier_part_info
GROUP BY supplier_part_desc, s_acctbal
HAVING SUM(ps_availqty) > 100
ORDER BY average_retailprice DESC, total_availqty DESC;

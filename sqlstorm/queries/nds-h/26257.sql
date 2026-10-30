
WITH DetailedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        l.l_quantity,
        l.l_extendedprice
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    p_partkey,
    REGEXP_REPLACE(p_name, '.*(a|e|i|o|u).*', 'REPLACED') AS modified_name,
    LEFT(supplier_name, 3) AS short_supplier_name,
    CONCAT('Total: ', ROUND(SUM(l_extendedprice), 2)) AS total_extended_price,
    COUNT(DISTINCT o_orderkey) AS order_count
FROM DetailedParts
WHERE CHAR_LENGTH(p_comment) > 10
GROUP BY p_partkey, p_name, supplier_name
HAVING COUNT(DISTINCT o_orderkey) > 2
ORDER BY total_extended_price DESC;

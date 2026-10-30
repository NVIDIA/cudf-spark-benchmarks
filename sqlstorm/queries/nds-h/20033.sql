WITH  supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, n.n_regionkey,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
), filtered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           CASE
               WHEN p.p_size IS NULL OR p.p_size = 0 THEN 'Unknown Size'
               WHEN p.p_size > 20 THEN 'Large'
               ELSE 'Small'
           END AS size_category
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_container IS NOT NULL
    )
), part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), order_stats AS (
    SELECT o.o_orderkey,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS returned_value,
           COUNT(DISTINCT l.l_orderkey) AS line_count,
           AVG(l.l_discount) AS avg_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT sd.s_name, fp.p_name, fp.size_category, ps.total_avail_qty, os.returned_value, os.line_count, os.avg_discount
FROM supplier_data sd
FULL OUTER JOIN filtered_parts fp ON sd.rank = 1
JOIN part_supplier ps ON ps.ps_partkey = fp.p_partkey
LEFT JOIN order_stats os ON os.o_orderkey = (SELECT MIN(o.o_orderkey) 
                                              FROM orders o 
                                              WHERE o.o_orderstatus IN ('O', 'F') 
                                              AND o.o_orderkey > 0)
WHERE sd.rank <= 5
AND (sd.n_regionkey IS NULL OR sd.n_regionkey IN (1, 2, 3)) 
ORDER BY sd.s_name, fp.p_name DESC, os.avg_discount ASC
LIMIT 20 OFFSET 10;

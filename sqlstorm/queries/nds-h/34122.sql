WITH  supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey) AS nation_name
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT sp.ps_suppkey, (SELECT su.s_name FROM supplier su WHERE su.s_suppkey = sp.ps_suppkey), 
           su.s_nationkey, su.s_acctbal, 
           (SELECT n.n_name FROM nation n WHERE n.n_nationkey = su.s_nationkey)
    FROM partsupp sp
    JOIN supplier su ON sp.ps_suppkey = su.s_suppkey
    WHERE su.s_acctbal > 2000.00
)
SELECT p.p_partkey, p.p_name, p.p_brand, AVG(l.l_extendedprice) AS avg_price,
       COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
       MAX(CASE WHEN l.l_shipdate > '1997-01-01' THEN l.l_quantity ELSE NULL END) AS max_recent_ship
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier_chain sc ON l.l_suppkey = sc.s_suppkey
WHERE l.l_discount BETWEEN 0.05 AND 0.10
  AND l.l_shipdate < cast('1998-10-01' as date)
  AND p.p_size IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING AVG(l.l_extendedprice) > (SELECT AVG(ps_supplycost)
                                   FROM partsupp
                                   WHERE ps_availqty > 0)
   OR SUM(l.l_quantity) > 100
ORDER BY avg_price DESC
LIMIT 10;
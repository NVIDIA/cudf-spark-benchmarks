WITH  order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
), ranked_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_orderkey) AS total_extended_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
), supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), nation_suppliers AS (
    SELECT n.n_name, s.s_suppkey, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'A%' OR n.n_name LIKE '%N%'
)
SELECT oh.o_orderkey, oh.o_orderdate, rli.l_partkey, rli.l_quantity, rli.total_extended_price,
       CASE 
           WHEN rli.total_extended_price IS NULL THEN 0 
           ELSE rli.total_extended_price 
       END AS calculated_price,
       ns.n_name, np.total_availqty
FROM order_hierarchy oh
LEFT JOIN ranked_lineitems rli ON oh.o_orderkey = rli.l_orderkey
FULL OUTER JOIN supplier_parts np ON rli.l_partkey = np.ps_partkey
JOIN nation_suppliers ns ON ns.s_suppkey = np.ps_suppkey
WHERE (oh.o_totalprice > 1000 AND rli.l_quantity < 10) 
   OR (oh.o_orderdate < cast('1998-10-01' as date) - INTERVAL '30 days' AND rli.total_extended_price IS NULL)
ORDER BY oh.o_orderdate DESC, calculated_price DESC;
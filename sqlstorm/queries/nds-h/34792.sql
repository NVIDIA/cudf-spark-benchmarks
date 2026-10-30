WITH  CTE_SupplierRank AS (
    SELECT s_suppkey, s_name, s_acctbal,
           RANK() OVER (ORDER BY s_acctbal DESC) AS supplier_rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
CTE_Location AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name,
           COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
),
CTE_OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           c.c_mktsegment, ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS segment_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT p.p_name, p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COALESCE(ctes.supplier_count, 0) AS supplier_count,
       cs.segment_rank
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN CTE_Location ctes ON p.p_brand = ctes.nation_name
LEFT JOIN CTE_OrderSummary cs ON cs.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
GROUP BY p.p_name, p.p_brand, ctes.supplier_count, cs.segment_rank
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
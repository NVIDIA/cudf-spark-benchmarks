WITH  capable_suppliers AS (
    SELECT s_suppkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
), popular_parts AS (
    SELECT p_partkey, p_name, COUNT(DISTINCT l_orderkey) AS order_count
    FROM part
    JOIN lineitem ON p_partkey = l_partkey
    WHERE l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY p_partkey, p_name
), nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY n.n_nationkey, n.n_name
), detailed_stats AS (
    SELECT n.n_name, COALESCE(ps.part_count, 0) AS part_count,
           COALESCE(ns.total_sales, 0) AS total_sales,
           COALESCE(cs.rank, 0) AS supplier_rank
    FROM nation n
    LEFT JOIN (SELECT ps_partkey, COUNT(*) AS part_count
                FROM partsupp
                GROUP BY ps_partkey) ps ON ps.ps_partkey IN (SELECT DISTINCT l_partkey FROM lineitem WHERE l_shipdate >= cast('1998-10-01' as date) - INTERVAL '60 days')
    LEFT JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
    LEFT JOIN capable_suppliers cs ON n.n_nationkey = cs.s_suppkey
    WHERE n.n_name LIKE 'N%'
), unique_brands AS (
    SELECT DISTINCT p_brand
    FROM part
    WHERE LENGTH(p_name) > 10
)
SELECT ds.n_name, ds.part_count, ds.total_sales, ds.supplier_rank, 
       string_agg(DISTINCT ub.p_brand, ', ') AS unique_brands
FROM detailed_stats ds
LEFT JOIN unique_brands ub ON ds.part_count > 5
GROUP BY ds.n_name, ds.part_count, ds.total_sales, ds.supplier_rank
ORDER BY ds.total_sales DESC, ds.part_count DESC
LIMIT 10 OFFSET 5;
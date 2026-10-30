WITH  supplier_agg AS (
    SELECT s_suppkey, SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_suppkey
    HAVING SUM(ps_supplycost * ps_availqty) > 100000
), nation_info AS (
    SELECT n_name, COUNT(DISTINCT s_suppkey) AS supplier_count,
           AVG(s_acctbal) AS avg_acctbal,
           MAX(s_acctbal) AS max_acctbal
    FROM supplier
    JOIN nation ON s_nationkey = n_nationkey
    GROUP BY n_name
), order_summary AS (
    SELECT o_custkey, COUNT(o_orderkey) AS total_orders,
           SUM(o_totalprice) AS total_spent,
           ROW_NUMBER() OVER(PARTITION BY o_custkey ORDER BY SUM(o_totalprice) DESC) AS order_rank
    FROM orders
    GROUP BY o_custkey
), filtered_line_items AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS net_price
    FROM lineitem
    WHERE l_returnflag = 'N' AND l_shipdate < cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY l_orderkey
), combined_results AS (
    SELECT n.n_name, si.supplier_count, si.avg_acctbal,
           os.total_orders, os.total_spent, li.net_price
    FROM nation_info si
    LEFT JOIN filtered_line_items li ON si.supplier_count > 10
    JOIN order_summary os ON os.total_orders > 5
    JOIN nation n ON n.n_name LIKE '%land%'
    WHERE n.n_nationkey IS NOT NULL
)
SELECT DISTINCT n_name, supplier_count, avg_acctbal, total_orders, total_spent, net_price
FROM combined_results
UNION ALL
SELECT 'Unaffected' AS n_name, 0 AS supplier_count, NULL AS avg_acctbal, 
       CASE WHEN SUM(total_orders) > 50 THEN 5 ELSE NULL END AS total_orders,
       0 AS total_spent, NULL AS net_price
FROM combined_results
WHERE total_orders IS NULL
GROUP BY total_orders
HAVING COUNT(*) > 1
ORDER BY n_name DESC NULLS LAST;
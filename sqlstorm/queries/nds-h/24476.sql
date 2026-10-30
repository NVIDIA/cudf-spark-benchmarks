
WITH  ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_type
), aggregated_orders AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           o.o_orderdate,
           COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY o.o_orderkey, o.o_orderdate
), doorbell_customers AS (
    SELECT c.c_custkey, c.c_name, 
           MAX(o.o_totalprice) AS max_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5 AND AVG(o.o_totalprice) IS NOT NULL
), enriched_suppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.supplier_rank,
           ds.max_order_value, 
           COALESCE(ds.max_order_value, 0) * SUM(ps.ps_supplycost) AS adjusted_value
    FROM ranked_suppliers rs
    LEFT JOIN doorbell_customers ds ON ds.max_order_value > 0
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    GROUP BY rs.s_suppkey, rs.s_name, rs.supplier_rank, ds.max_order_value
), fiscal_report AS (
    SELECT p.p_type, 
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
           SUM(es.adjusted_value) AS total_adjusted_value,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN enriched_suppliers es ON ps.ps_suppkey = es.s_suppkey
    GROUP BY p.p_type
    HAVING SUM(es.adjusted_value) > 100000 OR COUNT(DISTINCT ps.ps_suppkey) = 1
)
SELECT fr.p_type, 
       fr.unique_suppliers,
       fr.total_adjusted_value,
       fr.avg_supply_cost,
       RANK() OVER (ORDER BY fr.total_adjusted_value DESC) AS revenue_rank
FROM fiscal_report fr
WHERE fr.avg_supply_cost IS NOT NULL
ORDER BY fr.total_adjusted_value DESC;

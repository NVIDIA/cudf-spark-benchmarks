WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), order_summary AS (
    SELECT o.o_orderkey, o.o_orderstatus, DATE_TRUNC('month', o.o_orderdate) AS order_month, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, DATE_TRUNC('month', o.o_orderdate)
), customer_revenue AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_revenue) AS total_revenue
    FROM customer c
    JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
), region_summary AS (
    SELECT r.r_name, SUM(cr.total_revenue) AS total_revenue_by_region
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer_revenue cr ON cr.c_custkey = n.n_nationkey 
    GROUP BY r.r_name
)
SELECT ts.s_name AS supplier_name, rs.r_name AS region_name, 
       rs.total_revenue_by_region, ts.total_supply_cost
FROM top_suppliers ts
JOIN region_summary rs ON ts.total_supply_cost > rs.total_revenue_by_region
ORDER BY ts.total_supply_cost DESC, rs.total_revenue_by_region DESC
LIMIT 10;

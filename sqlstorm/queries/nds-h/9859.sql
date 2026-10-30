WITH Supplier_Summary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available_qty, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
Customer_Summary AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
Region_Summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS total_nations, SUM(CASE WHEN c.c_acctbal > 0 THEN 1 ELSE 0 END) AS total_positive_customers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rs.r_name AS region_name, COUNT(DISTINCT cs.c_custkey) AS customer_count,
       SUM(cs.total_order_value) AS total_order_value, SUM(ss.total_supply_cost) AS total_supply_cost
FROM Region_Summary rs
JOIN nation n ON rs.r_regionkey = n.n_regionkey
JOIN Customer_Summary cs ON n.n_nationkey = cs.c_nationkey
JOIN Supplier_Summary ss ON n.n_nationkey = ss.s_nationkey
GROUP BY rs.r_name
ORDER BY total_order_value DESC, customer_count DESC
LIMIT 100;

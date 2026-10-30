WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count, 
           SUM(o.o_totalprice) AS total_order_value
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
AggregatedData AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, MAX(r.r_name) AS region_name, 
           AVG(rn.total_supply_cost) AS avg_supply_cost, ns.customer_count, ns.total_order_value
    FROM part p
    JOIN RankedSuppliers rn ON rn.total_supply_cost > 10000
    JOIN supplier s ON p.p_partkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN NationStats ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, ns.customer_count, ns.total_order_value
)
SELECT AVG(avg_supply_cost) AS average_supplier_cost, SUM(total_order_value) AS total_sales_value
FROM AggregatedData
WHERE region_name IS NOT NULL
GROUP BY region_name
ORDER BY total_sales_value DESC;

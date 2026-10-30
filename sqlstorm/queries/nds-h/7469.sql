WITH SupplierCost AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
),
PartDetails AS (
    SELECT p.p_name, p.p_size, SUM(l.l_quantity) AS total_quantity, SUM(l.l_extendedprice) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_name, p.p_size
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT r.r_name AS region, 
       ns.n_name AS nation, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(pc.total_revenue) AS total_revenue_generated,
       SUM(sc.total_cost) AS total_supplier_cost,
       AVG(os.total_spent) AS average_order_value
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
JOIN customer c ON c.c_nationkey = ns.n_nationkey
JOIN OrderSummary os ON c.c_custkey = os.o_custkey
JOIN PartDetails pc ON pc.total_quantity > 100
JOIN SupplierCost sc ON sc.total_cost < 100000
GROUP BY r.r_name, ns.n_name
ORDER BY total_revenue_generated DESC, customer_count DESC;

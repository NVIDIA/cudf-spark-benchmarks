
WITH top_customers AS (
    SELECT c_custkey, c_name, SUM(o_totalprice) AS total_spent
    FROM customer
    JOIN orders ON c_custkey = o_custkey
    GROUP BY c_custkey, c_name
    HAVING SUM(o_totalprice) > 10000
), 
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_nationkey
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 50
), 
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num,
           o.o_custkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    c.c_name,
    n.n_name AS nation,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS net_revenue,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    AVG(p.ps_supplycost) AS avg_supply_cost,
    MAX(od.o_orderdate) AS latest_order_date
FROM top_customers c
LEFT JOIN order_details od ON c.c_custkey = od.o_custkey
JOIN part_supplier_info p ON p.p_partkey = od.l_partkey
JOIN nation n ON p.s_nationkey = n.n_nationkey
WHERE n.n_regionkey IN (
    SELECT r_regionkey 
    FROM region 
    WHERE r_name LIKE 'Asia%'
) 
AND od.l_quantity > 0
GROUP BY c.c_name, n.n_name
HAVING SUM(od.l_extendedprice * (1 - od.l_discount)) > 5000
ORDER BY net_revenue DESC
LIMIT 10;

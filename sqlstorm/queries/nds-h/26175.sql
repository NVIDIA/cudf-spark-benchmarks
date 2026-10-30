
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, COUNT(ps.ps_availqty) AS total_parts, 
           SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_name
    HAVING COUNT(ps.ps_availqty) > 10
), RegionNations AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT sp.s_name, sp.p_name, sp.total_parts, sp.total_cost, 
       rn.r_name AS region_name, co.c_name AS customer_name, 
       co.total_orders, co.average_order_value
FROM SupplierParts sp
JOIN RegionNations rn ON rn.nation_count > 3
JOIN CustomerOrders co ON co.total_orders > 5
WHERE sp.total_cost > 5000
ORDER BY sp.total_parts DESC, co.average_order_value DESC;

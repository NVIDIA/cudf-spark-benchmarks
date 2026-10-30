WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
RegionWiseOrderCount AS (
    SELECT n.n_regionkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_regionkey
)
SELECT 
    r.r_name AS region_name,
    rc.order_count,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers_count,
    SUM(rs.total_cost) AS total_supplier_cost
FROM region r
JOIN RegionWiseOrderCount rc ON r.r_regionkey = rc.n_regionkey
LEFT JOIN HighValueCustomers hvc ON hvc.total_spent > 10000
LEFT JOIN RankedSupplier rs ON rs.rnk <= 10
GROUP BY r.r_name, rc.order_count
ORDER BY rc.order_count DESC, total_supplier_cost DESC;

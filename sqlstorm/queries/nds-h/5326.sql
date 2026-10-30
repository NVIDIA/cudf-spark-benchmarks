WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RegionStats AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ss.s_name,
    ss.total_supply_value
FROM CustomerOrders cs
JOIN SupplierStats ss ON cs.total_spent > 10000
JOIN RegionStats rs ON rs.nation_count > 5 
ORDER BY rs.r_name, cs.total_spent DESC, ss.total_supply_value DESC
LIMIT 50;

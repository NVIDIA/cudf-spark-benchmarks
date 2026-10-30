WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RegionNations AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rd.r_regionkey,
    SUM(sd.total_supply_cost) AS regional_supply_cost,
    AVG(c.c_acctbal) AS average_customer_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM RegionNations rd
JOIN SupplierDetails sd ON sd.s_nationkey = rd.n_nationkey
JOIN customer c ON c.c_nationkey = rd.n_nationkey
JOIN orders o ON o.o_custkey = c.c_custkey
WHERE sd.total_supply_cost > 10000
GROUP BY rd.r_regionkey
ORDER BY regional_supply_cost DESC, average_customer_balance ASC;

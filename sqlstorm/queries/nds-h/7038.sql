WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT si.s_suppkey, si.s_name, r.r_name AS region_name
    FROM SupplierInfo si
    JOIN nation n ON si.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE si.total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM SupplierInfo
    )
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey
),
FinalCalculation AS (
    SELECT h.s_suppkey, h.s_name, h.region_name, c.order_count
    FROM HighCostSuppliers h
    LEFT JOIN CustomerOrderCount c ON h.s_suppkey = c.c_custkey
)
SELECT f.s_suppkey, f.s_name, f.region_name, COALESCE(f.order_count, 0) AS order_count
FROM FinalCalculation f
ORDER BY f.region_name, f.order_count DESC
LIMIT 10;

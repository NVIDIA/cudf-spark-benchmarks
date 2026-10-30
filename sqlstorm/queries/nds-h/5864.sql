
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
HighCostSuppliers AS (
    SELECT 
        r.r_name,
        s.s_name,
        s.s_nationkey,
        s.total_supply_cost
    FROM RankedSuppliers s
    JOIN region r ON s.s_nationkey = r.r_regionkey
    WHERE s.rank <= 3
)
SELECT 
    r.r_name AS region,
    COUNT(s.s_nationkey) AS supplier_count,
    AVG(s.total_supply_cost) AS avg_supply_cost,
    SUM(s.total_supply_cost) AS total_supply_cost
FROM HighCostSuppliers s
JOIN region r ON s.s_nationkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_supply_cost DESC;

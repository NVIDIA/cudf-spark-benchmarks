WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionStats AS (
    SELECT
        n.n_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(ss.total_supply_cost) AS avg_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierStats ss ON ss.s_suppkey = s.s_suppkey
    GROUP BY n.n_regionkey
)
SELECT
    r.r_name,
    rs.supplier_count,
    rs.avg_supply_cost
FROM region r
JOIN RegionStats rs ON r.r_regionkey = rs.n_regionkey
WHERE rs.avg_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
ORDER BY rs.avg_supply_cost DESC;

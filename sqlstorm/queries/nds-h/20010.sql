WITH SupplyStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS effective_total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierPerformance AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        COALESCE(hv.o_orderkey, -1) AS high_value_order,
        ss.total_supply_cost,
        ss.part_count
    FROM SupplyStats ss
    LEFT JOIN HighValueOrders hv ON ss.rn = hv.o_orderkey
),
RegionStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_regionkey
)
SELECT 
    rp.n_name AS nation_name,
    rp.avg_acctbal,
    sp.total_supply_cost,
    sp.part_count,
    rp.supplier_count
FROM RegionStats rp
LEFT JOIN SupplierPerformance sp ON rp.n_nationkey = sp.s_suppkey
WHERE (rp.avg_acctbal IS NOT NULL AND rp.supplier_count > 1)
   OR (sp.high_value_order IS NOT NULL AND sp.total_supply_cost > 5000)
ORDER BY rp.n_name, sp.total_supply_cost DESC;

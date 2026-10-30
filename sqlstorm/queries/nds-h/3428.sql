WITH RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY ps.ps_partkey
),
OrderLineSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderdate < '1997-12-31'
    GROUP BY o.o_orderkey
)

SELECT 
    r.region_name,
    p.total_available_quantity,
    p.avg_supply_cost,
    o.total_revenue,
    o.unique_parts
FROM 
    RegionSummary r
LEFT JOIN PartSupplierSummary p ON r.nation_count > 5
LEFT JOIN OrderLineSummary o ON o.total_revenue > 10000
ORDER BY 
    r.region_name,
    p.total_available_quantity DESC,
    o.total_revenue DESC
LIMIT 100;
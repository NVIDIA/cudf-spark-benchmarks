WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name AS region_name,
        n.n_nationkey,
        n.n_name AS nation_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rn.region_name,
    rn.nation_name,
    ss.s_name,
    ss.total_available_qty,
    ss.avg_supply_cost,
    os.total_orders,
    os.total_spent,
    COALESCE(NULLIF(os.total_spent, 0), 1) / ss.avg_supply_cost AS cost_spent_ratio
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    OrderSummary os ON ss.s_suppkey = os.c_custkey
JOIN 
    RegionNation rn ON rn.n_nationkey = os.c_custkey
WHERE 
    (os.total_orders > 5 OR ss.total_available_qty >= 100) 
    AND (ss.avg_supply_cost IS NOT NULL AND ss.avg_supply_cost < 500)
ORDER BY 
    cost_spent_ratio DESC
LIMIT 10;

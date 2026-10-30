WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
CombinedStats AS (
    SELECT 
        n.n_name,
        COALESCE(ss.total_parts, 0) AS total_parts,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(ss.total_supply_value, 0) AS total_supply_value,
        COALESCE(cs.total_revenue, 0) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN 
        CustomerStats cs ON n.n_nationkey = cs.c_nationkey
)
SELECT 
    n_name,
    total_parts,
    total_orders,
    total_supply_value,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    CombinedStats
WHERE 
    total_orders > 10
    OR total_supply_value > 10000
ORDER BY 
    total_revenue DESC, total_parts ASC;

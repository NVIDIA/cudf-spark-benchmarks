WITH RegionSuppliers AS (
    SELECT 
        r.r_name AS region,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        region,
        s_suppkey,
        s_name,
        total_supply_cost,
        RANK() OVER (PARTITION BY region ORDER BY total_supply_cost DESC) AS rank
    FROM 
        RegionSuppliers
)
SELECT 
    ts.region,
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 5
ORDER BY 
    ts.region, ts.total_supply_cost DESC;

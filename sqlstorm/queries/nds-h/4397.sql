WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_available_qty,
        sp.total_supply_cost,
        CASE 
            WHEN sp.total_supply_cost > 100000 THEN 'High'
            WHEN sp.total_supply_cost BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS cost_category
    FROM 
        SupplierParts sp
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    hs.s_name AS supplier_name,
    hs.total_available_qty,
    hs.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY hs.total_supply_cost DESC) AS rank_within_region,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueSuppliers hs ON n.n_nationkey = hs.s_suppkey
LEFT JOIN 
    lineitem li ON li.l_suppkey = hs.s_suppkey
WHERE 
    hs.total_available_qty IS NOT NULL
GROUP BY 
    r.r_name, n.n_name, hs.s_name, hs.total_available_qty, hs.total_supply_cost
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY 
    r.r_name, rank_within_region;

WITH  report AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        COUNT(DISTINCT l_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM 
        lineitem
    WHERE 
        l_shipdate >= '1997-01-01' AND l_shipdate <= '1997-12-31'
    GROUP BY 
        l_orderkey
),
supplier_revenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
top_suppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sr.total_supply_cost DESC) AS rnk
    FROM 
        supplier_revenue sr
)
SELECT 
    r.l_orderkey,
    r.total_revenue,
    COALESCE(ts.s_suppkey, 0) AS top_supplier_key,
    COALESCE(ts.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN r.unique_parts > 5 THEN 'High Variety'
        ELSE 'Low Variety'
    END AS part_variety
FROM 
    report r
LEFT JOIN 
    top_suppliers ts ON r.rn = ts.rnk
WHERE 
    r.total_revenue IS NOT NULL 
ORDER BY 
    r.total_revenue DESC;
WITH total_sales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= '1996-01-01' AND l_shipdate < '1997-01-01'
    GROUP BY 
        l_partkey
),
supplier_part AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    SUM(sp.ps_supplycost * sp.ps_availqty) AS total_cost,
    (COALESCE(ts.total_revenue, 0) - SUM(sp.ps_supplycost * sp.ps_availqty)) AS profit,
    CASE 
        WHEN COALESCE(ts.total_revenue, 0) = 0 THEN NULL 
        ELSE ROUND(((COALESCE(ts.total_revenue, 0) - SUM(sp.ps_supplycost * sp.ps_availqty)) / COALESCE(ts.total_revenue, 1)) * 100, 2)
    END AS profit_margin
FROM 
    supplier_part sp
LEFT JOIN 
    total_sales ts ON sp.p_partkey = ts.l_partkey
GROUP BY 
    sp.p_partkey, sp.p_name, ts.total_revenue
ORDER BY 
    profit DESC
LIMIT 10;
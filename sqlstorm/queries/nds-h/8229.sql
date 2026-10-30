WITH total_sales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_shipdate > '1996-01-01' AND l.l_shipdate < '1996-12-31'
    GROUP BY 
        ps.ps_partkey
), part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        r.r_name AS region_name,
        sum(ts.revenue) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        total_sales ts ON p.p_partkey = ts.ps_partkey
    WHERE 
        p.p_brand LIKE 'Brand#%'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, r.r_name
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.region_name,
    pd.total_revenue
FROM 
    part_details pd
WHERE 
    pd.total_revenue = (SELECT MAX(total_revenue) FROM part_details)
ORDER BY 
    pd.region_name, pd.p_brand;
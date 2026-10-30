WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA' 
        AND l.l_shipdate >= '1996-01-01' 
        AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSellingParts AS (
    SELECT 
        p_partkey,
        p_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.ps_availqty, 0) as available_quantity,
    COALESCE(ps.ps_supplycost, 0) as supply_cost,
    t.total_sales
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSellingParts t ON p.p_partkey = t.p_partkey
ORDER BY 
    t.total_sales DESC;

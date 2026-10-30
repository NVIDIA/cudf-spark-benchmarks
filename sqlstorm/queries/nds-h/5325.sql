
WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    GROUP BY 
        p.p_partkey, p.p_name
),
HighRevenueParts AS (
    SELECT 
        r.p_partkey,
        r.p_name,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank = 1
)
SELECT 
    h.p_partkey,
    h.p_name,
    h.total_sales,
    s.s_name,
    s.s_acctbal,
    n.n_name,
    r.r_name
FROM 
    HighRevenueParts h
JOIN 
    partsupp ps ON h.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    h.total_sales DESC
LIMIT 10;

WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
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
    WHERE 
        r.r_name = 'ASIA' AND 
        l.l_shipdate >= '1997-01-01' AND 
        l.l_shipdate < '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
)
SELECT 
    total_sales,
    COUNT(*) AS count_of_sales,
    AVG(total_sales) AS avg_sales
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    total_sales
ORDER BY 
    total_sales DESC;
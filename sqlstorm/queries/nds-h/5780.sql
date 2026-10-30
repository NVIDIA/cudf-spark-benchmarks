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
    WHERE 
        n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'EUROPE')
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    rs.p_partkey, 
    rs.p_name, 
    rs.total_sales 
FROM 
    RankedSales rs 
WHERE 
    rs.sales_rank <= 10 
ORDER BY 
    rs.total_sales DESC;

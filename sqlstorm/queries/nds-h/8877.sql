
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
TopParts AS (
    SELECT 
        r.r_name AS region_name, 
        p.p_name AS part_name, 
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        part p ON rs.p_partkey = p.p_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    region_name, 
    COUNT(part_name) AS top_part_count, 
    AVG(total_sales) AS average_sales 
FROM 
    TopParts
GROUP BY 
    region_name
ORDER BY 
    top_part_count DESC, average_sales DESC;


WITH  region_sales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
),
top_regions AS (
    SELECT 
        region,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        region_sales
    WHERE 
        total_sales IS NOT NULL
)
SELECT 
    t.region,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    CASE 
        WHEN t.total_sales > 1000000 THEN 'High'
        WHEN t.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    top_regions t
LEFT JOIN 
    nation n ON t.region = n.n_name
WHERE 
    t.rank <= 10
ORDER BY 
    total_sales DESC;

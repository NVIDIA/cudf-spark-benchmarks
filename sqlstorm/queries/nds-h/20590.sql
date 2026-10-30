
WITH regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        n.n_name, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
ranked_sales AS (
    SELECT 
        nation_name,
        region_name,
        total_sales,
        order_count,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
)
SELECT 
    r.nation_name,
    r.region_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.order_count, 0) AS order_count,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'Unranked'
        ELSE CAST(rs.sales_rank AS STRING)
    END AS sales_rank
FROM 
    regional_sales AS r
FULL OUTER JOIN 
    ranked_sales AS rs ON r.nation_name = rs.nation_name AND r.region_name = rs.region_name
ORDER BY 
    r.region_name, rs.sales_rank;

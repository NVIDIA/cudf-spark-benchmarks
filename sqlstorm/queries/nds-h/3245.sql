WITH regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    GROUP BY 
        n.n_name, r.r_name
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
    rs.nation_name,
    rs.region_name,
    rs.total_sales,
    rs.order_count,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Highest Sales'
        ELSE NULL
    END AS sales_rank_comment
FROM 
    ranked_sales rs
WHERE 
    rs.total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM 
            ranked_sales
    )
ORDER BY 
    rs.region_name, rs.total_sales DESC;
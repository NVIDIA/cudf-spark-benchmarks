WITH  regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
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
    GROUP BY 
        n.n_name, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
ranked_sales AS (
    SELECT 
        nation_name, 
        region_name, 
        total_sales,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
)
SELECT 
    rs.region_name,
    rs.nation_name,
    rs.total_sales
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.region_name, rs.total_sales DESC;

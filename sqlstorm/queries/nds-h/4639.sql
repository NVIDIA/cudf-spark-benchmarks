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
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        n.n_name, r.r_name
), ranked_sales AS (
    SELECT 
        nation_name,
        region_name,
        total_sales,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
)
SELECT 
    rs.nation_name,
    rs.region_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.sales_rank, 0) AS sales_rank
FROM 
    ranked_sales rs
FULL OUTER JOIN 
    (SELECT 
         r.r_name AS region_name 
     FROM 
         region r) regions ON rs.region_name = regions.region_name
WHERE 
    rs.sales_rank <= 5 OR rs.sales_rank IS NULL
ORDER BY 
    rs.region_name, rs.sales_rank;
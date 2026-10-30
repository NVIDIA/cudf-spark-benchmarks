WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
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
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
), 
SalesWithRank AS (
    SELECT 
        nation_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), 
ZeroSalesNation AS (
    SELECT 
        n.n_name AS nation_name 
    FROM 
        nation n
    LEFT JOIN 
        SalesWithRank s ON n.n_name = s.nation_name
    WHERE 
        s.nation_name IS NULL
)
SELECT 
    COALESCE(sw.nation_name, z.nation_name) AS nation_name,
    COALESCE(sw.total_sales, 0) AS total_sales,
    COALESCE(sw.order_count, 0) AS order_count,
    CASE 
        WHEN sw.sales_rank IS NOT NULL THEN 'Ranked'
        ELSE 'No Sales'
    END AS sales_status
FROM 
    SalesWithRank sw
FULL OUTER JOIN 
    ZeroSalesNation z ON sw.nation_name = z.nation_name
ORDER BY 
    nation_name;
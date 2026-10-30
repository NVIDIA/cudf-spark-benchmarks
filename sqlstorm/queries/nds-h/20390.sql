WITH RegionalSales AS (
    SELECT 
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
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
), 
SalesRanked AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), 
QualifiedRegions AS (
    SELECT 
        sr.region_name,
        sr.total_sales,
        sr.order_count
    FROM 
        SalesRanked sr
    WHERE 
        sr.sales_rank <= 5
    OR (sr.total_sales IS NULL AND sr.order_count > 10)
)

SELECT 
    q.region_name,
    q.total_sales,
    COALESCE(q.order_count, (SELECT COUNT(*) FROM orders WHERE o_orderdate < DATE '1995-01-01')) AS fallback_order_count,
    CASE 
        WHEN q.total_sales IS NULL THEN 'No Sales'
        WHEN q.total_sales < 50000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    QualifiedRegions q
LEFT JOIN 
    (SELECT 
         n.n_name AS nation_name,
         SUM(p.p_retailprice) AS avg_price 
     FROM 
         nation n
     JOIN 
         supplier s ON n.n_nationkey = s.s_nationkey
     JOIN 
         partsupp ps ON s.s_suppkey = ps.ps_suppkey
     JOIN 
         part p ON ps.ps_partkey = p.p_partkey
     GROUP BY 
         n.n_name
     HAVING 
         AVG(p.p_retailprice) > 100) AS high_price_nations ON q.region_name = high_price_nations.nation_name
ORDER BY 
    q.total_sales DESC NULLS LAST;

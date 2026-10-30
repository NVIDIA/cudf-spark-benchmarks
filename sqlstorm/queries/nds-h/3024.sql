WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
), 
TopSales AS (
    SELECT 
        nation_name, total_sales, order_count
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    r.r_name AS region_name,
    ts.nation_name,
    COALESCE(ts.total_sales, 0) AS sales,
    COALESCE(ts.order_count, 0) AS orders,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_sales > 100000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    (SELECT nation_name, total_sales, order_count FROM TopSales) ts ON r.r_name = ts.nation_name
ORDER BY 
    r.r_name, sales DESC;
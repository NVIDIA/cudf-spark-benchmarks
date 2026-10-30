WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderstatus IN ('F', 'P') 
)

SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Highest Sales'
        ELSE 'Regular Sales'
    END AS order_category
FROM 
    TopOrders o
LEFT JOIN 
    RankedSales rs ON o.o_orderkey = rs.l_orderkey
WHERE 
    o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
ORDER BY 
    total_sales DESC,
    o.o_orderdate;

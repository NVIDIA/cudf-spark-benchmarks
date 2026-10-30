
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopSales AS (
    SELECT 
        r.r_name AS region_name,
        d.n_name AS nation_name,
        SUM(ro.total_sales) AS region_sales
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation d ON c.c_nationkey = d.n_nationkey
    JOIN 
        region r ON d.n_regionkey = r.r_regionkey
    WHERE 
        ro.sales_rank <= 5
    GROUP BY 
        r.r_name, d.n_name
)

SELECT 
    ts.region_name,
    ts.nation_name,
    ts.region_sales,
    COALESCE(ROUND((ts.region_sales / NULLIF(SUM(ts.region_sales) OVER (), 0)) * 100, 2), 0) AS sales_percentage
FROM 
    TopSales ts
ORDER BY 
    ts.region_sales DESC;

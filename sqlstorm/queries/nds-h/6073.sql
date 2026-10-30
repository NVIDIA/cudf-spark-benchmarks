WITH SalesData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.order_count) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SalesData sd ON n.n_name = sd.nation_name
    GROUP BY 
        r.r_name
)
SELECT 
    rs.region_name,
    rs.total_sales,
    rs.total_orders,
    RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
FROM 
    RegionSales rs
WHERE 
    rs.total_sales > 1000000
ORDER BY 
    rs.total_sales DESC;

WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        region_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        RankedOrders o
    WHERE 
        rank <= 10
    GROUP BY 
        region_name
)
SELECT 
    t.region_name,
    t.total_sales,
    t.total_orders,
    (SELECT AVG(total_sales) FROM TopOrders) AS avg_sales_per_region,
    (SELECT MAX(total_sales) FROM TopOrders) AS max_sales
FROM 
    TopOrders t
ORDER BY 
    t.total_sales DESC;
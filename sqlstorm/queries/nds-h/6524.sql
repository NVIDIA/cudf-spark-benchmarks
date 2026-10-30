WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSales AS (
    SELECT 
        ro.o_orderkey,
        ro.total_sales,
        c.c_name,
        c.c_nationkey,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        ro.sales_rank <= 10
)
SELECT 
    ts.o_orderkey,
    ts.total_sales,
    ts.c_name,
    ts.nation_name
FROM 
    TopSales ts
ORDER BY 
    ts.total_sales DESC;
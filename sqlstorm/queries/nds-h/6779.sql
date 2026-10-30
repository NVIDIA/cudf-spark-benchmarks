WITH SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
RankedSales AS (
    SELECT 
        sd.c_custkey,
        sd.c_name,
        sd.nation_name,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (PARTITION BY sd.nation_name ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.nation_name,
    rs.c_name,
    rs.total_sales,
    rs.order_count,
    rs.sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.nation_name, rs.total_sales DESC;
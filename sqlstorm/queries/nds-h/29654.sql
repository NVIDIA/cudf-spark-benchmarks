WITH CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_linenumber) AS total_items
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
),
RankedSales AS (
    SELECT 
        c_name,
        o_orderkey,
        o_orderdate,
        total_sales,
        total_items,
        ROW_NUMBER() OVER (PARTITION BY c_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerOrders
)
SELECT 
    r.c_name,
    r.o_orderkey,
    r.o_orderdate,
    r.total_sales,
    r.total_items,
    s.p_name,
    s.p_brand,
    s.p_type
FROM 
    RankedSales r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    part s ON l.l_partkey = s.p_partkey
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.c_name, r.total_sales DESC;

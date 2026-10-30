WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
), OrderSummary AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        c_name, 
        total_sales,
        distinct_parts,
        RANK() OVER (PARTITION BY o_orderdate ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RankedOrders
)

SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.c_name,
    os.total_sales,
    os.distinct_parts
FROM 
    OrderSummary os
WHERE 
    os.sales_rank <= 10
ORDER BY 
    os.o_orderdate, os.total_sales DESC;
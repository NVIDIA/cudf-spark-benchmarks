WITH  Sales_CTE AS (
    SELECT 
        n.n_name AS nation,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        n.n_name, c.c_mktsegment
),
Ranked_Sales AS (
    SELECT 
        nation,
        c_mktsegment,
        total_sales,
        RANK() OVER (PARTITION BY nation ORDER BY total_sales DESC) AS sales_rank
    FROM 
        Sales_CTE
)
SELECT 
    nation,
    c_mktsegment,
    total_sales
FROM 
    Ranked_Sales
WHERE 
    sales_rank <= 3
ORDER BY 
    nation, total_sales DESC;

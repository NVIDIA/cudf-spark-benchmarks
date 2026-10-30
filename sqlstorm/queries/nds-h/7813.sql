WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o_orderdate) AS sale_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        sale_month
),
top_selling_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    ms.sale_month,
    tsp.p_name,
    tsp.total_sales
FROM 
    monthly_sales ms
JOIN 
    top_selling_parts tsp ON tsp.total_sales = (
        SELECT MAX(total_sales)
        FROM top_selling_parts
    )
ORDER BY 
    ms.sale_month;
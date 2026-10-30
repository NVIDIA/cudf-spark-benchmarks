
WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopSales AS (
    SELECT 
        c.c_nationkey,
        SUM(S.total_sales) AS nation_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(S.total_sales) DESC) AS nation_rank
    FROM 
        SalesCTE AS S
    JOIN 
        customer AS c ON S.c_name = c.c_name
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(t.nation_sales, 0) AS total_sales,
    CASE 
        WHEN t.nation_rank IS NOT NULL THEN 'Top Performer' 
        ELSE 'Non-Performer' 
    END AS status
FROM 
    region AS r
LEFT JOIN 
    TopSales AS t ON r.r_regionkey = t.c_nationkey
ORDER BY 
    total_sales DESC;

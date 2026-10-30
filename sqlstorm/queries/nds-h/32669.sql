WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_nationkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
HighSales AS (
    SELECT 
        sc.c_custkey,
        sc.c_name,
        sc.total_sales,
        CASE
            WHEN sc.sales_rank <= 5 THEN 'Top Performer'
            ELSE 'Regular Performer'
        END AS performance_level
    FROM 
        SalesCTE sc
)
SELECT 
    n.n_name AS nation,
    hs.performance_level,
    COUNT(hs.c_custkey) AS customer_count,
    AVG(hs.total_sales) AS average_sales
FROM 
    HighSales hs
JOIN 
    supplier s ON hs.c_custkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name, hs.performance_level
HAVING 
    COUNT(hs.c_custkey) > 0
ORDER BY 
    nation, performance_level;
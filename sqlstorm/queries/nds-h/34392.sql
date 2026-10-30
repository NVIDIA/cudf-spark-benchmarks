
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
BenchmarkSales AS (
    SELECT 
        n.n_nationkey,
        SUM(s.total_sales) AS sales_by_nation
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
),
AggregateSales AS (
    SELECT 
        AVG(sales_by_nation) AS average_sales,
        MAX(sales_by_nation) AS max_sales
    FROM 
        BenchmarkSales
)
SELECT 
    n.n_name,
    bs.sales_by_nation,
    COALESCE(ps.ps_availqty, 0) AS available_qty,
    a.average_sales,
    a.max_sales
FROM 
    BenchmarkSales bs
JOIN 
    nation n ON bs.n_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON n.n_nationkey = ps.ps_suppkey
CROSS JOIN 
    AggregateSales a
WHERE 
    bs.sales_by_nation > (SELECT AVG(sales_by_nation) FROM BenchmarkSales) 
ORDER BY 
    bs.sales_by_nation DESC
LIMIT 10 OFFSET 10;

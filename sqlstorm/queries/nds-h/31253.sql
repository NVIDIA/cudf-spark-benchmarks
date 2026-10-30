
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_nationkey
), NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.total_sales) AS nation_sales
    FROM 
        nation n 
    LEFT JOIN 
        SalesCTE s ON n.n_nationkey = s.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    COALESCE(ns.nation_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(ns.nation_sales, 0) >= 100000 THEN 'High Sales'
        WHEN COALESCE(ns.nation_sales, 0) BETWEEN 50000 AND 99999 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    RANK() OVER (ORDER BY COALESCE(ns.nation_sales, 0) DESC) AS sales_rank
FROM 
    nation n 
LEFT JOIN 
    NationSales ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%Europe%')
ORDER BY 
    total_sales DESC;

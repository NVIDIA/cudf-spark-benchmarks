WITH  Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS SalesRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
Top_Customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(sc.TotalSales) AS AnnualSales
    FROM 
        customer c
    LEFT JOIN 
        Sales_CTE sc ON c.c_custkey = sc.o_orderkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(sc.TotalSales) > 10000
)
SELECT 
    c.c_name,
    COALESCE(c.c_acctbal, 0) AS AccountBalance,
    COALESCE(tc.AnnualSales, 0) AS TotalSales,
    CASE 
        WHEN tc.AnnualSales IS NOT NULL THEN 'High Value'
        ELSE 'Low Value'
    END AS CustomerValue
FROM 
    customer c
FULL OUTER JOIN 
    Top_Customers tc ON c.c_custkey = tc.c_custkey
WHERE 
    c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
ORDER BY 
    COALESCE(tc.AnnualSales, 0) DESC, c.c_name
LIMIT 100;
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS SalesRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), RankedSales AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cs.TotalSales,
        cs.SalesRank,
        COALESCE(n.n_name, 'Unknown') AS NationName,
        CASE 
            WHEN cs.SalesRank <= 5 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS CustomerType
    FROM 
        SalesCTE cs
    LEFT JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    COUNT(*) AS CustomerCount,
    AVG(TotalSales) AS AverageSales,
    MIN(TotalSales) AS MinimalSales,
    MAX(TotalSales) AS MaximumSales,
    STRING_AGG(DISTINCT CONCAT(c_name, ' (', CustomerType, ')'), ', ') AS CustomerList
FROM 
    RankedSales
WHERE 
    TotalSales IS NOT NULL
GROUP BY 
    COALESCE(NationName, 'Global')
HAVING 
    AVG(TotalSales) > (SELECT AVG(TotalSales) FROM SalesCTE WHERE TotalSales IS NOT NULL)
ORDER BY 
    CustomerCount DESC
LIMIT 10 OFFSET 0;
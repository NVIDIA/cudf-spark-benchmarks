
WITH RegionalSales AS (
    SELECT 
        r.r_name AS Region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS SalesRank
    FROM 
        region r 
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), 

HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        ROUND(AVG(o.o_totalprice), 2) AS AvgOrderValue
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)

SELECT 
    rs.Region,
    rs.TotalSales,
    ROW_NUMBER() OVER (ORDER BY rs.TotalSales DESC) AS TotalSalesRank,
    (SELECT COUNT(DISTINCT c2.c_custkey) 
     FROM customer c2 
     WHERE c2.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) AS CustomerCount,
    COALESCE(hvc.AvgOrderValue, 0) AS AvgOrderValue
FROM 
    RegionalSales rs
LEFT JOIN 
    HighValueCustomers hvc ON hvc.AvgOrderValue > 1000
WHERE 
    rs.TotalSales > (SELECT AVG(TotalSales) FROM RegionalSales)
ORDER BY 
    rs.TotalSales DESC 
LIMIT 10;

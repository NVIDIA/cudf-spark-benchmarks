
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        s.s_name AS SupplierName,
        SUM(l.l_quantity) AS TotalQuantity,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalSales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        c.c_acctbal > 5000
    GROUP BY 
        c.c_custkey, c.c_name, s.s_name
    HAVING 
        SUM(l.l_quantity) > 50
),
SalesSummary AS (
    SELECT 
        sc.c_custkey AS cust_key,
        SUM(sc.TotalSales) AS AnnualSales
    FROM 
        SalesCTE sc
    GROUP BY 
        sc.c_custkey
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    COALESCE(ss.AnnualSales, 0) AS AnnualSales,
    tc.TotalQuantity,
    CASE 
        WHEN ss.AnnualSales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS SalesStatus
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesSummary ss ON tc.c_custkey = ss.cust_key
ORDER BY 
    tc.TotalQuantity DESC, AnnualSales DESC;

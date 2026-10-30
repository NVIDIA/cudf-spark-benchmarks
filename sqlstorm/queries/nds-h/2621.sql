WITH SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(od.TotalRevenue, 0) AS TotalSpent,
        CASE 
            WHEN c.c_acctbal = 0 THEN 'No Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS BalanceStatus
    FROM 
        customer c
    LEFT JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.TotalCost,
        RANK() OVER (ORDER BY s.TotalCost DESC) AS SupplierRank
    FROM 
        SupplierStatistics s
)
SELECT 
    cs.c_name,
    cs.TotalSpent,
    cs.BalanceStatus,
    ts.s_name AS TopSupplier,
    ts.TotalCost
FROM 
    CustomerSummary cs
LEFT JOIN 
    TopSuppliers ts ON cs.TotalSpent > 0 AND ts.SupplierRank <= 5
WHERE 
    cs.TotalSpent IS NOT NULL
ORDER BY 
    cs.TotalSpent DESC, cs.c_name ASC
LIMIT 10;
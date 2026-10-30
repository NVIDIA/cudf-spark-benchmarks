WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS PriceRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.o_totalprice,
    s.s_name AS SupplierName,
    s.TotalSupplyCost,
    COALESCE(o.PriceRank, 0) AS OrderRank,
    CASE 
        WHEN o.o_totalprice > 1000 THEN 'High Value' 
        WHEN o.o_totalprice > 500 THEN 'Medium Value' 
        ELSE 'Low Value'
    END AS OrderValueCategory
FROM 
    CustomerOrders c
LEFT JOIN 
    RankedOrders o ON c.c_custkey = o.o_custkey 
LEFT JOIN 
    SupplierInfo s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    s.TotalSupplyCost IS NOT NULL
ORDER BY 
    c.c_name, o.o_orderkey DESC;
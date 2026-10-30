WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 YEAR')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 5
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 3
)
SELECT 
    r.o_orderkey,
    r.o_orderdate, 
    r.o_totalprice,
    c.c_name,
    s.s_name,
    pd.p_name,
    pd.SupplierCount,
    s.TotalSupplyCost,
    COALESCE(c.TotalSpent, 0) AS CustomerTotalSpent
FROM 
    RankedOrders r
JOIN 
    CustomerOrders c ON c.OrderCount >= (SELECT AVG(OrderCount) FROM CustomerOrders)
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
JOIN 
    SupplierInfo s ON l.l_suppkey = s.s_suppkey
WHERE 
    pd.SupplierCount IS NOT NULL
AND 
    r.OrderRank <= 5
ORDER BY 
    r.o_orderdate DESC, s.TotalSupplyCost DESC;
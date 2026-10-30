WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(l.l_quantity) AS TotalSold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)

SELECT 
    r.r_name,
    SUM(CASE WHEN c.TotalSpent IS NULL THEN 0 ELSE c.TotalSpent END) AS TotalCustomerSpending,
    SUM(CASE WHEN sp.TotalAvailable IS NULL THEN 0 ELSE sp.TotalAvailable END) AS TotalPartsAvailable,
    SUM(pd.TotalSold) AS TotalPartsSold,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(CASE WHEN ro.OrderRank = 1 THEN o.o_totalprice ELSE NULL END) AS AvgHighestOrderPrice
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    SupplierParts sp ON ps.ps_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerSpending c ON s.s_suppkey = c.c_custkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
GROUP BY 
    r.r_name
ORDER BY 
    TotalCustomerSpending DESC;
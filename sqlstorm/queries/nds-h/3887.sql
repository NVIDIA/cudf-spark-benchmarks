
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
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
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RegionCustomer AS (
    SELECT 
        n.n_name AS RegionName,
        COUNT(DISTINCT c.c_custkey) AS CustomerCount
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'Europe'
    GROUP BY 
        n.n_name
)

SELECT 
    r.RegionName,
    r.CustomerCount,
    p.p_name,
    p.Revenue,
    s.s_name,
    s.TotalSupplyCost
FROM 
    RegionCustomer r
LEFT JOIN 
    PartDetails p ON p.Revenue > 1000
INNER JOIN 
    SupplierDetails s ON s.TotalSupplyCost > (SELECT AVG(TotalSupplyCost) FROM SupplierDetails)
WHERE 
    r.CustomerCount > 10
ORDER BY 
    r.CustomerCount DESC, p.Revenue DESC
LIMIT 20;

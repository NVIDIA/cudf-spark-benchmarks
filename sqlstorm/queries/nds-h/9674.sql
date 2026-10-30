WITH SupplierDetails AS (
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
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderRevenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
)
SELECT 
    nd.n_name AS NationName,
    nd.region_name,
    sd.s_name AS SupplierName,
    COUNT(DISTINCT co.o_orderkey) AS OrderCount,
    SUM(co.OrderRevenue) AS TotalRevenue,
    MAX(sd.TotalSupplyCost) AS MaxSupplyCost
FROM 
    SupplierDetails sd
JOIN 
    NationDetails nd ON sd.s_nationkey = nd.n_nationkey
LEFT JOIN 
    CustomerOrders co ON nd.n_nationkey = co.c_custkey
GROUP BY 
    nd.n_name, nd.region_name, sd.s_name
ORDER BY 
    TotalRevenue DESC, OrderCount DESC
LIMIT 10;
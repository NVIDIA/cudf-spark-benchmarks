WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplyRank
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
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_comment,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    s.s_name AS SupplierName,
    r.r_name AS RegionName,
    c.c_name AS CustomerName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    AVG(l.l_quantity) AS AvgQuantity,
    MIN(l.l_shipdate) AS FirstShipDate,
    MAX(l.l_shipdate) AS LastShipDate,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS OrderVolume
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    AND c.c_acctbal > 1000
GROUP BY 
    s.s_name, r.r_name, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    TotalRevenue DESC, SupplierName;
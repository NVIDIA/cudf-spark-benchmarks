WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailableQty,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(ss.TotalAvailableQty, 0) AS TotalAvailableQty,
        COALESCE(ss.AvgSupplyCost, 0) AS AvgSupplyCost
    FROM 
        part p
    LEFT JOIN 
        SupplierStats ss ON p.p_partkey = ss.ps_partkey
), CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name AS CustomerName,
    p.p_name AS PartName,
    p.TotalAvailableQty,
    p.AvgSupplyCost,
    CASE 
        WHEN r.OrderRank = 1 THEN 'Highest Order'
        ELSE 'Other Orders'
    END AS OrderType
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    PartSupplierInfo p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrderSummary co ON r.c_name = co.c_name
WHERE 
    (p.AvgSupplyCost < 100.00 OR p.p_retailprice > 50.00) 
    AND r.o_orderdate >= DATE '1997-01-01'
ORDER BY 
    r.o_orderdate DESC, 
    r.o_orderkey;
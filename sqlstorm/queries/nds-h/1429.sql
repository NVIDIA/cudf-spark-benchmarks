
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_partkey) AS TotalItemsSold
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(s.s_name, 'No Suppliers') AS SupplierStats,
    o.TotalRevenue,
    o.TotalItemsSold,
    r.o_orderdate,
    r.o_totalprice
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierStats s ON r.o_orderkey = s.s_suppkey
LEFT JOIN 
    OrderDetails o ON r.o_orderkey = o.l_orderkey
WHERE 
    r.OrderRank <= 5
    AND r.o_totalprice > 
        (SELECT AVG(o_totalprice) FROM RankedOrders WHERE o_orderdate = r.o_orderdate)
ORDER BY 
    r.o_orderdate, r.o_totalprice DESC;

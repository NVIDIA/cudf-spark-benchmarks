WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
),
HighestRevenueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.TotalRevenue,
        RANK() OVER (ORDER BY sr.TotalRevenue DESC) AS SupplierRank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierRevenue sr ON s.s_suppkey = sr.ps_suppkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(hs.s_name, 'Unknown Supplier') AS SupplierName,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Order Complete'
        WHEN r.o_orderstatus = 'P' THEN 'Pending Order'
        ELSE 'Other Status'
    END AS OrderStatusDescription
FROM 
    RankedOrders r
LEFT JOIN 
    HighestRevenueSuppliers hs ON hs.SupplierRank <= 5
WHERE 
    r.OrderRank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
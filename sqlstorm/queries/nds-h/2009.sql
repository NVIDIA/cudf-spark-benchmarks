WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS TotalParts,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        s.s_name,
        ss.TotalParts,
        ss.TotalSupplyCost,
        ROW_NUMBER() OVER (ORDER BY ss.TotalParts DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.TotalParts > 0
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ts.s_name AS SupplierName,
    COUNT(l.l_orderkey) AS LineItemCount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemRevenue,
    COALESCE(SUM(l.l_tax), 0) AS TotalTax,
    CASE 
        WHEN ro.o_totalprice > 1000 THEN 'High Value'
        WHEN ro.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS OrderValueCategory
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
GROUP BY 
    ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ts.s_name
HAVING 
    COUNT(l.l_orderkey) > 0 AND SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY 
    ro.o_orderdate DESC, LineItemCount DESC;
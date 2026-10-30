WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        SUM(ps.ps_supplycost) AS TotalCost
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
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        AVG(o.o_totalprice) AS AvgOrderValue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    r.r_name,
    COUNT(DISTINCT l.l_orderkey) AS TotalLineItems,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    CASE WHEN SUM(l.l_tax) IS NULL THEN 0 ELSE SUM(l.l_tax) END AS TotalTax,
    c.c_name AS TopCustomer,
    so.s_name AS TopSupplier
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier so ON l.l_suppkey = so.s_suppkey
JOIN 
    nation n ON so.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 50 
    AND o.o_orderstatus IN ('F', 'P') 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, c.c_name, so.s_name
HAVING 
    SUM(l.l_discount) < 0.1
ORDER BY 
    TotalRevenue DESC, TotalLineItems DESC;
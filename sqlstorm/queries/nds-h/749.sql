WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS AvgOrderValue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredNation AS (
    SELECT 
        n.n_nationkey, 
        n.n_name 
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Asia%')
)
SELECT 
    rp.o_orderkey,
    rp.o_orderdate,
    rp.o_totalprice,
    rp.o_orderpriority,
    sp.s_name,
    sp.TotalSupplyCost,
    cs.c_name,
    cs.AvgOrderValue
FROM 
    RankedOrders rp
LEFT JOIN 
    SupplierParts sp ON rp.o_orderkey = sp.ps_partkey
LEFT JOIN 
    CustomerSummary cs ON rp.o_orderkey = cs.c_custkey
WHERE 
    rp.OrderRank <= 10 
    AND (cs.AvgOrderValue IS NULL OR cs.AvgOrderValue > 5000.00)
ORDER BY 
    rp.o_orderdate DESC, 
    sp.TotalSupplyCost ASC;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM 
        RankedOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.OrderRank <= 10
    GROUP BY 
        r.o_orderkey
)
SELECT 
    sp.s_name,
    COUNT(DISTINCT hvo.o_orderkey) AS OrderCount,
    SUM(sp.ps_supplycost * sp.ps_availqty) AS TotalSupplyCost,
    AVG(hvo.TotalValue) AS AvgOrderValue
FROM 
    SupplierParts sp
JOIN 
    HighValueOrders hvo ON sp.ps_partkey IN (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        GROUP BY 
            ps.ps_partkey 
        HAVING 
            SUM(ps.ps_availqty) > 1000
    )
GROUP BY 
    sp.s_name
ORDER BY 
    OrderCount DESC, 
    TotalSupplyCost DESC
LIMIT 5;

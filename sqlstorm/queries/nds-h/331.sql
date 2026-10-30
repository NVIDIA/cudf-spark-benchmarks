WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        AVG(ps.ps_supplycost) AS AverageSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * l.l_quantity * (1 - l.l_discount) 
            ELSE 0 
        END) AS DiscountedSales,
    COALESCE(SUM(st.TotalAvailableQuantity), 0) AS TotalAvailableQuantitySupplied,
    AVG(st.AverageSupplyCost) AS AverageCostPerPart
FROM 
    part p 
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierStats st ON s.s_suppkey = st.s_suppkey
JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 20 AND 
    p.p_retailprice IS NOT NULL AND 
    n.n_name IN (SELECT n2.n_name FROM nation n2 WHERE n2.n_regionkey = r.r_regionkey)
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    TotalOrders DESC, Region;
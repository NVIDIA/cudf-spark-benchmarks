WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    o.o_orderdate,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS overall_order_rank
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size <= (SELECT AVG(p_size) FROM part)
    AND p.p_retailprice > (
        SELECT MIN(p_retailprice) 
        FROM part 
        WHERE p_type LIKE 'plastic%'
    )
    AND EXISTS (
        SELECT 1
        FROM HighValueSuppliers hvs 
        WHERE hvs.s_suppkey = l.l_suppkey
    )
ORDER BY 
    supplier_count DESC, 
    p.p_retailprice ASC;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderstatus IN ('O', 'F')
),
SuppliersCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
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
    p.p_brand,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    rc.total_supply_cost,
    ro.o_orderkey,
    ro.o_orderdate
FROM 
    part p
LEFT JOIN 
    SuppliersCosts rc ON p.p_partkey = rc.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
    AND p.p_comment LIKE '%fragile%'
    AND (ro.o_totalprice IS NULL OR ro.o_totalprice < 5000)
ORDER BY 
    rc.total_supply_cost DESC, 
    p.p_name ASC
LIMIT 100;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01'
),
TopHighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.c_name = c.c_name
    WHERE 
        o.rn <= 10
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
)
SELECT 
    tp.o_orderkey,
    tp.o_totalprice,
    tp.o_orderdate,
    tp.c_name,
    tp.c_acctbal,
    sp.ps_partkey,
    sp.supplier_count,
    sp.total_supply_cost
FROM 
    TopHighValueOrders tp
JOIN 
    lineitem l ON tp.o_orderkey = l.l_orderkey
JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
WHERE 
    sp.supplier_count > 5
ORDER BY 
    tp.o_totalprice DESC, 
    tp.o_orderdate ASC
LIMIT 50;
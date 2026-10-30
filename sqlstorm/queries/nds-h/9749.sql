WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
RankedSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        sp.ps_availqty,
        sp.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY sp.p_partkey ORDER BY sp.ps_supplycost ASC) AS rn
    FROM 
        SupplierParts sp
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P')
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    sp.p_partkey,
    sp.p_name,
    sp.ps_supplycost
FROM 
    CustomerOrders co
JOIN 
    RankedSuppliers sp ON co.o_orderkey = sp.s_suppkey
WHERE 
    sp.rn = 1
ORDER BY 
    co.o_orderdate DESC, 
    co.o_totalprice DESC
LIMIT 100;

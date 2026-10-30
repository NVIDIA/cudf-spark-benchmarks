
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_totalprice,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), 
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 10
)
SELECT 
    r.o_orderkey,
    r.rank_totalprice,
    sp.p_name,
    sp.s_name,
    sp.total_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierPartDetails sp ON r.o_orderkey = sp.p_partkey
WHERE 
    r.rank_totalprice <= 3 
    AND (r.o_orderstatus = 'F' OR r.o_orderstatus = 'P')
ORDER BY 
    r.o_orderkey DESC, sp.total_supply_cost ASC
LIMIT 100;

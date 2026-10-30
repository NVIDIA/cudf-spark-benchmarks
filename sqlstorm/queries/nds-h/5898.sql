WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND 
        s.s_acctbal > 1000.00
    AND 
        l.l_discount BETWEEN 0.05 AND 0.1
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    r.supplier_name,
    r.p_name
FROM 
    RankedOrders r
WHERE 
    r.rn = 1
ORDER BY 
    r.o_totalprice DESC
LIMIT 100;
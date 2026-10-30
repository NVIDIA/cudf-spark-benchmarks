
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_availqty) AS available_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    sd.s_name AS supplier_name,
    rp.p_name AS most_expensive_part,
    rp.p_retailprice AS most_expensive_price,
    sd.available_parts AS supplier_available_parts
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
LEFT JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.price_rank = 1
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND c.c_acctbal > 500
GROUP BY 
    c.c_name, o.o_orderkey, sd.s_name, rp.p_name, rp.p_retailprice, sd.available_parts
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;

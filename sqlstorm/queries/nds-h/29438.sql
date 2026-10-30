WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), HighValueParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.short_comment,
        rp.supplier_name
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
)
SELECT 
    hvp.p_partkey,
    hvp.p_name,
    hvp.short_comment,
    hvp.supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_totalprice
FROM 
    HighValueParts hvp
JOIN 
    lineitem l ON hvp.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    hvp.supplier_name LIKE '%Inc%'
ORDER BY 
    hvp.p_partkey, o.o_totalprice DESC;

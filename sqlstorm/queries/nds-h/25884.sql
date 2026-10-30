
WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' (', s.s_address, ')') AS supplier_info,
        SUBSTRING(p.p_comment, 1, 10) AS comment_snippet
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 10 AND 
        p.p_brand LIKE 'Brand%' AND 
        ps.ps_availqty > 0
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_mktsegment
    HAVING 
        COUNT(o.o_orderkey) > 5 AND 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    psi.p_name,
    psi.p_brand,
    psi.p_type,
    psi.supplier_info,
    coi.c_name,
    coi.total_orders,
    coi.total_spent
FROM 
    PartSupplierInfo psi
JOIN 
    CustomerOrderInfo coi ON psi.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
WHERE 
    psi.comment_snippet LIKE 'Nice%' 
ORDER BY 
    psi.p_name, coi.total_spent DESC;

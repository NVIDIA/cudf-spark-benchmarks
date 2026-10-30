
WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' (', s.s_name, ')') AS combined_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT(c.c_name, ' - Order #', o.o_orderkey) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    psd.p_partkey,
    psd.p_name,
    psd.supplier_name,
    psd.ps_availqty,
    psd.ps_supplycost,
    psd.combined_name,
    cod.c_custkey,
    cod.c_name,
    cod.o_orderkey,
    cod.o_totalprice,
    cod.o_orderdate,
    cod.order_info
FROM 
    PartSupplierDetails psd
JOIN 
    CustomerOrderDetails cod ON psd.ps_supplycost < cod.o_totalprice
WHERE 
    TRIM(psd.combined_name) LIKE '%chain%' 
    AND EXTRACT(YEAR FROM cod.o_orderdate) = 1997
ORDER BY 
    psd.ps_supplycost DESC, cod.o_totalprice ASC;

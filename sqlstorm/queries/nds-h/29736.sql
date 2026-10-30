
WITH ConcatenatedData AS (
    SELECT 
        CONCAT(p.p_name, ' ', p.p_mfgr) AS part_detail,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderstatus AS order_status,
        l.l_returnflag AS return_flag
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    part_detail,
    nation_name,
    supplier_name,
    customer_name,
    order_status,
    return_flag,
    LENGTH(part_detail) AS part_length,
    CHAR_LENGTH(nation_name) AS nation_length,
    COALESCE(NULLIF(TRIM(supplier_name), ''), 'No Supplier') AS effective_supplier,
    CONCAT('Customer: ', customer_name, ' | Nation: ', nation_name) AS customer_info
FROM 
    ConcatenatedData
WHERE 
    LENGTH(part_detail) > 20
ORDER BY 
    part_length DESC, customer_name ASC
LIMIT 100;

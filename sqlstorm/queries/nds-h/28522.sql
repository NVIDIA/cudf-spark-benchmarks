
WITH ProcessedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_acctbal,
        REPLACE(s.s_comment, 'OLD', 'NEW') AS modified_comment,
        CONCAT('Supplier:', s.s_name, ' located at ', s.s_address) AS supplier_info
    FROM 
        supplier s
    WHERE 
        LENGTH(s.s_comment) > 50
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000 
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        CONCAT(p.p_name, ' - Price:', p.p_retailprice) AS part_info
    FROM 
        part p
    WHERE 
        p.p_retailprice > 30.00
)
SELECT 
    ps.ps_partkey,
    ps.ps_suppkey,
    ps.ps_availqty,
    ps.ps_supplycost,
    cs.c_name,
    cs.order_count,
    pd.short_comment,
    ps.ps_comment,
    ps.ps_supplycost * cs.total_spent AS total_invoiced,
    pd.part_info AS ps_part_info
FROM 
    partsupp ps
JOIN 
    ProcessedSuppliers ss ON ps.ps_suppkey = ss.s_suppkey
JOIN 
    CustomerOrders cs ON cs.total_spent > 2000
JOIN 
    PartDetails pd ON pd.p_partkey = ps.ps_partkey
WHERE 
    ss.modified_comment LIKE '%NEW%'
ORDER BY 
    total_invoiced DESC, ss.s_name ASC;


WITH StringAggregate AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        CONCAT_WS('|', p.p_name, p.p_mfgr, p.p_comment) AS combined_string,
        LENGTH(CONCAT_WS('|', p.p_name, p.p_mfgr, p.p_comment)) AS string_length
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_comment
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('Germany', 'France', 'USA')
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sa.p_partkey,
    sa.combined_string,
    sa.string_length,
    fs.s_name,
    fo.c_name,
    fo.order_count,
    fo.total_spent
FROM 
    StringAggregate sa
JOIN 
    FilteredSuppliers fs ON sa.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 1000 LIMIT 1)
JOIN 
    CustomerOrders fo ON fo.order_count > 5
WHERE 
    sa.string_length > 100
ORDER BY 
    sa.string_length DESC, fo.total_spent DESC;

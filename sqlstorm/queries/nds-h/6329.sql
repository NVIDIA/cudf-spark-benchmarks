WITH  supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_retailprice
), 
top_suppliers AS (
    SELECT 
        supplier_parts.s_suppkey,
        supplier_parts.s_name,
        supplier_parts.p_name,
        supplier_parts.total_available
    FROM 
        supplier_parts
    ORDER BY 
        supplier_parts.total_available DESC
    LIMIT 10
)
SELECT 
    t.s_name AS supplier_name,
    t.p_name AS part_name,
    t.total_available,
    AVG(o.o_totalprice) AS average_order_value
FROM 
    top_suppliers t
JOIN 
    orders o ON o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c WHERE c.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n WHERE n.n_regionkey = (
                SELECT r.r_regionkey 
                FROM region r WHERE r.r_name = 'EUROPE'
            )
        )
    )
GROUP BY 
    t.s_suppkey, t.s_name, t.p_name, t.total_available
ORDER BY 
    average_order_value DESC;

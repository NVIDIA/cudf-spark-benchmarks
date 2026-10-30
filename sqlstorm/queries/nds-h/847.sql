
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUM(ps.ps_availqty) AS total_availqty,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_availqty) DESC) AS rank_avail
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
high_spenders AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        customer_orders co
    INNER JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 10000
)
SELECT 
    rp.p_name,
    rp.p_type,
    rp.total_availqty,
    co.c_name AS high_spender_name,
    co.order_count,
    co.total_spent
FROM 
    ranked_parts rp
LEFT JOIN 
    high_spenders hsp ON rp.p_type = (SELECT MAX(p_type) FROM ranked_parts WHERE rank_avail < 5)
JOIN 
    customer_orders co ON hsp.c_custkey = co.c_custkey
WHERE 
    rp.rank_avail <= 5
ORDER BY 
    rp.total_availqty DESC, co.total_spent DESC;


WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS part_info,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_acctbal,
        REPLACE(s.s_comment, 'obsolete', 'updated') AS updated_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.part_info,
    sd.s_name,
    sd.updated_comment,
    co.c_name,
    co.order_count,
    co.total_spent,
    co.last_order_date
FROM 
    ranked_parts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier_details sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    customer_orders co ON sd.s_suppkey = co.c_custkey
WHERE 
    rp.rn = 1
ORDER BY 
    co.total_spent DESC, rp.p_name ASC;

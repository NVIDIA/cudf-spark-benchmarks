WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%plastic%'
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUBSTRING(s.s_address, 1, 20) AS short_address
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    co.total_orders,
    co.total_spending
FROM 
    ranked_parts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier_details sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    customer_orders co ON sd.s_nationkey = co.c_custkey
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_spending DESC;

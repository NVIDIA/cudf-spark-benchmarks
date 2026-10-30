
WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size = (
            SELECT MAX(p1.p_size) 
            FROM part p1 
            WHERE p1.p_type LIKE '%metal%'
        )
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(ps.ps_availqty) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    sd.s_name,
    sd.s_address,
    hvo.c_name,
    hvo.total_line_value
FROM 
    ranked_parts rp
JOIN 
    supplier_details sd ON sd.supply_count > 5
JOIN 
    high_value_orders hvo ON hvo.o_totalprice > 5000
WHERE 
    rp.rn = 1
ORDER BY 
    rp.p_name;

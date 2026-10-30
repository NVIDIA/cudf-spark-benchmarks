WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        REPLACE(LOWER(p.p_type), ' ', '_') AS type_reformatted,
        p.p_retailprice * 1.1 AS adjusted_price 
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10 
        AND p.p_retailprice < 100.00
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' - ', s.s_phone) AS contact_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 500.00
),
orders_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(DISTINCT l.l_partkey) AS parts_count
    FROM 
        orders o
    INNER JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
customer_info AS (
    SELECT 
        c.c_custkey,
        UPPER(c.c_name) AS upper_name,
        LEFT(c.c_address, 20) AS short_address,
        c.c_mktsegment
    FROM 
        customer c
    WHERE 
        c.c_acctbal BETWEEN 1000.00 AND 5000.00
),
final_benchmark AS (
    SELECT 
        pp.p_partkey,
        pp.p_name,
        pp.type_reformatted,
        pp.adjusted_price,
        sd.contact_info,
        os.parts_count,
        ci.upper_name,
        ci.short_address,
        ci.c_mktsegment
    FROM 
        processed_parts pp
    JOIN 
        supplier_details sd ON pp.p_partkey = sd.s_nationkey
    JOIN 
        orders_summary os ON os.o_orderkey = pp.p_partkey 
    JOIN 
        customer_info ci ON ci.c_custkey = os.o_orderkey
    ORDER BY 
        pp.adjusted_price DESC
)
SELECT * FROM final_benchmark
WHERE parts_count > 2;
WITH string_agg AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        CONCAT(p.p_name, ' - ', p.p_brand, ' (', p.p_type, ')') AS aggregated_string,
        LENGTH(CONCAT(p.p_name, ' - ', p.p_brand, ' (', p.p_type, ')')) AS string_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
), 
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_nationkey, 
        CONCAT(s.s_name, ' ', s.s_address) AS supplier_details
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE 'United%'
), 
customer_info AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        CONCAT(c.c_name, ' (', c.c_mktsegment, ')') AS customer_details
    FROM 
        customer c
), 
final_selection AS (
    SELECT 
        o.o_orderkey, 
        c.customer_details,
        s.supplier_details,
        sa.aggregated_string,
        sa.string_length
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier_info s ON l.l_suppkey = s.s_suppkey
    JOIN 
        customer_info c ON o.o_custkey = c.c_custkey
    JOIN 
        string_agg sa ON l.l_partkey = sa.p_partkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND sa.string_length > 40
)
SELECT 
    customer_details, 
    supplier_details, 
    aggregated_string
FROM 
    final_selection
ORDER BY 
    customer_details, 
    supplier_details;


WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
formatted_details AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        CONCAT(pd.p_brand, ' ', pd.p_type) AS part_description,
        pd.p_size,
        pd.p_container,
        pd.ps_supplycost,
        pd.supplier_name,
        pd.supplier_address,
        pd.customer_name,
        CAST(pd.o_orderdate AS DATE) AS formatted_order_date,
        pd.o_totalprice,
        LENGTH(pd.p_comment) AS comment_length
    FROM 
        part_details pd
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.part_description,
    f.p_size,
    f.p_container,
    ROUND(f.ps_supplycost * 1.2, 2) AS adjusted_supply_cost,
    f.supplier_name,
    f.supplier_address,
    f.customer_name,
    f.formatted_order_date,
    f.o_totalprice,
    f.comment_length
FROM 
    formatted_details f
WHERE 
    f.comment_length > 20
ORDER BY 
    f.o_totalprice DESC
LIMIT 100;

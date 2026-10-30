
WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'the', 'THE') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' - ', s.s_address) AS full_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 500.00
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        UPPER(c.c_name) AS upper_name
    FROM 
        customer c
),
OrdersInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open' 
            ELSE 'Closed' 
        END AS order_status_desc
    FROM 
        orders o
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    sd.full_info AS supplier_info,
    ci.upper_name AS customer_name,
    oi.order_month,
    oi.order_status_desc,
    pd.modified_comment
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    OrdersInfo oi ON li.l_orderkey = oi.o_orderkey
JOIN 
    CustomerInfo ci ON oi.o_custkey = ci.c_custkey
WHERE 
    pd.comment_length > 20
ORDER BY 
    pd.p_brand, oi.order_month DESC;

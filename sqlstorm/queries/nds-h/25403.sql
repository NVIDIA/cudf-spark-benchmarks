
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT(s.s_name, ' (', s.s_address, ')') AS supplier_details,
        LENGTH(s.s_comment) AS comment_length,
        SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment
    FROM 
        supplier s
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_container,
        p.p_comment,
        REPLACE(p.p_comment, 'soft', 'hard') AS updated_comment,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
),
OrdersSummarized AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        ci.total_orders,
        ci.total_spent,
        CONCAT(c.c_name, ' - ', SUBSTRING(c.c_address FROM 1 FOR 15)) AS customer_summary
    FROM 
        customer c
    JOIN 
        OrdersSummarized ci ON c.c_custkey = ci.o_custkey
),
JoinedData AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        si.supplier_details,
        pi.p_name,
        pi.updated_comment,
        ci.customer_summary
    FROM 
        partsupp ps
    JOIN 
        SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
    JOIN 
        PartInfo pi ON ps.ps_partkey = pi.p_partkey
    JOIN 
        CustomerInfo ci ON si.s_suppkey = ci.c_custkey
)
SELECT 
    jd.customer_summary,
    jd.supplier_details,
    jd.p_name,
    jd.updated_comment
FROM 
    JoinedData jd
WHERE 
    jd.updated_comment LIKE '%hard%'
ORDER BY 
    jd.customer_summary, jd.supplier_details;

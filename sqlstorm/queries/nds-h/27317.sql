WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS name_mfgr,
        REPLACE(p.p_comment, 'bad', 'good') AS modified_comment,
        SUBSTRING(p.p_comment, 1, 10) AS comment_substring
    FROM part p
), CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        REGEXP_REPLACE(c.c_address, '[^A-Za-z0-9 ]', '') AS cleaned_address
    FROM customer c
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    sp.p_partkey,
    sp.name_length,
    sp.name_upper,
    ci.c_custkey,
    ci.cleaned_address,
    os.total_lineitems,
    os.total_sales,
    os.avg_quantity
FROM StringProcessing sp
JOIN CustomerInfo ci ON ci.c_custkey % 10 = sp.p_partkey % 10
JOIN OrderSummary os ON os.total_lineitems > 5
WHERE sp.modified_comment LIKE '%good%'
ORDER BY sp.name_length DESC, os.total_sales DESC
LIMIT 100;

WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
    WHERE 
        p.p_size > 10
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUBSTRING(s.s_address, 1, 20) AS short_address
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    pi.p_name,
    pi.p_brand,
    pi.p_type,
    pi.p_retailprice,
    si.s_name AS supplier_name,
    si.short_address,
    od.o_orderkey,
    od.o_orderstatus,
    od.line_item_count,
    od.total_price,
    CONCAT(pi.short_comment, '... ') AS truncated_comment
FROM 
    PartInfo pi
JOIN 
    partsupp ps ON pi.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    OrderDetails od ON ps.ps_partkey = od.o_orderkey
WHERE 
    pi.comment_length > 20 
    AND od.total_price > 1000
ORDER BY 
    pi.p_brand, od.total_price DESC
LIMIT 50;

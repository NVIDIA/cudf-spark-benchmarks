
WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 15
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment, 
        CHAR_LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        SUBSTRING(o.o_comment, 1, 20) AS short_order_comment
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE('1998-10-01') - INTERVAL '30 days'
)
SELECT 
    pd.p_partkey, 
    pd.p_name, 
    pd.p_mfgr, 
    pd.p_brand, 
    sd.s_suppkey, 
    sd.s_name, 
    od.o_orderkey, 
    od.o_orderstatus, 
    od.o_totalprice,
    CONCAT(pd.short_comment, '...', ' (', pd.comment_length, ' chars)') AS formatted_comment,
    CONCAT(sd.s_comment, ' (Length: ', sd.supplier_comment_length, ' chars)') AS supplier_comment_info,
    CONCAT(od.short_order_comment, '...') AS order_comment_preview
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrderDetails od ON ps.ps_partkey = od.o_orderkey
ORDER BY 
    pd.p_retailprice DESC, 
    sd.s_acctbal DESC
LIMIT 100;

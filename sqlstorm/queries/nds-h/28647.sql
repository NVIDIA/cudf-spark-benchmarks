
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        RANK() OVER (ORDER BY LENGTH(p.p_name) DESC, CHAR_LENGTH(p.p_comment) DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        REPLACE(s.s_comment, 'supplier', 'vendor') AS modified_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    si.modified_comment,
    od.total_sales,
    CONCAT('Part: ', rp.p_name, '; Supplier: ', si.s_name, '; Sales: ', od.total_sales) AS summary
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON rp.p_partkey = si.s_suppkey
JOIN 
    OrderDetails od ON rp.p_partkey = od.o_orderkey
WHERE 
    rp.rank <= 10
ORDER BY 
    rp.rank;

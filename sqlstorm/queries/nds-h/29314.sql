WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT('Supplier ', s.s_name, ' located at ', s.s_address) AS supplier_info,
        REGEXP_REPLACE(s.s_comment, 'bad|awful|poor', 'good') AS sanitized_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        CONCAT(p.p_name, ' (', p.p_size, '): $', p.p_retailprice) AS part_info
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CONCAT('Order ', o.o_orderkey, ' on ', o.o_orderdate, ': $', o.o_totalprice) AS order_info
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
), LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CONCAT('Line Item ', l.l_orderkey, '-', l.l_linenumber, ' with quantity ', l.l_quantity) AS line_item_info
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1
)
SELECT 
    sd.s_name,
    sd.s_address,
    pd.part_info,
    od.order_info,
    lid.line_item_info,
    sd.sanitized_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    LineItemDetails lid ON lid.l_partkey = pd.p_partkey
JOIN 
    OrderDetails od ON lid.l_orderkey = od.o_orderkey
WHERE 
    sd.s_name LIKE '%Inc%'
ORDER BY 
    sd.s_name, od.o_orderdate DESC;

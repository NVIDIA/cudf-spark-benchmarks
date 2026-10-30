
WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        CONCAT('Part: ', p.p_name, ' | Type: ', p.p_type, ' | Brand: ', p.p_brand) AS part_description
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment,
        CONCAT('Supplier: ', s.s_name, ' | Phone: ', s.s_phone) AS supplier_info
    FROM 
        supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_address, 
        c.c_phone, 
        c.c_acctbal, 
        c.c_mktsegment, 
        LEFT(c.c_comment, 50) AS short_comment, 
        CONCAT('Customer: ', c.c_name, ' | Segment: ', c.c_mktsegment) AS customer_info
    FROM 
        customer c
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        CONCAT('Order: ', o.o_orderkey, ' | Total Price: $', o.o_totalprice) AS order_summary
    FROM 
        orders o
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    pd.part_description,
    sd.supplier_info,
    cd.customer_info,
    od.order_summary,
    lid.total_price_after_discount
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrderDetails od ON od.o_orderkey = ps.ps_partkey
JOIN 
    LineItemDetails lid ON lid.l_orderkey = od.o_orderkey
JOIN 
    CustomerDetails cd ON cd.c_custkey = od.o_custkey
WHERE 
    pd.p_retailprice > 100.00 AND 
    od.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    lid.total_price_after_discount DESC;

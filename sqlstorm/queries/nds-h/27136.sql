WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        CONCAT(p.p_name, ' ', p.p_brand, ' ', p.p_type) AS full_description,
        LENGTH(CONCAT(p.p_name, ' ', p.p_brand, ' ', p.p_type)) AS description_length
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
        LENGTH(s.s_name) AS supplier_name_length
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        o.o_clerk, 
        o.o_shippriority, 
        o.o_comment,
        DATE_PART('year', o.o_orderdate) AS order_year
    FROM 
        orders o
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount, 
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    pd.full_description,
    pd.description_length,
    sd.supplier_name_length,
    od.order_year,
    lis.total_price_after_discount,
    lis.line_item_count
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    LineItemSummary lis ON ps.ps_partkey = lis.l_orderkey
JOIN 
    OrderDetails od ON lis.l_orderkey = od.o_orderkey
WHERE 
    pd.description_length > 30 
    AND sd.supplier_name_length > 10
ORDER BY 
    pd.description_length DESC, 
    sd.supplier_name_length DESC;

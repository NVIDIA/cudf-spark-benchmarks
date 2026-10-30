WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        r.r_name AS region_name,
        CONCAT(s.s_name, ' located at ', s.s_address, ', contact: ', s.s_phone) AS supplier_details
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_comment,
        CONCAT(p.p_name, ' by ', p.p_brand, ' available in ', ps.ps_availqty, ' units, priced at $', ps.ps_supplycost) AS part_supplier_details
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderLineInfo AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        o.o_orderstatus,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CONCAT('Order ', o.o_orderkey, ' has ', l.l_quantity, ' of item ' , l.l_partkey, ' (price: $', l.l_extendedprice, ') with status ', o.o_orderstatus) AS order_line_details
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
)
SELECT 
    si.supplier_details,
    psi.part_supplier_details,
    oli.order_line_details
FROM 
    SupplierInfo si
JOIN 
    PartSupplierInfo psi ON si.s_suppkey = psi.ps_suppkey
JOIN 
    OrderLineInfo oli ON psi.ps_partkey = oli.l_partkey
WHERE 
    si.region_name = 'ASIA' 
    AND oli.l_discount > 0.1
ORDER BY 
    si.supplier_details, 
    psi.part_supplier_details, 
    oli.order_line_details;

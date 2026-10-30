
WITH SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, 
               ' with availability ', ps.ps_availqty, 
               ' at a supply cost of ', CAST(ps.ps_supplycost AS DECIMAL(10, 2))) AS supplier_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        CONCAT(c.c_name, ' has an order ', o.o_orderkey, 
               ' with total price ', CAST(o.o_totalprice AS DECIMAL(10, 2)), 
               ' and status ', o.o_orderstatus) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
LineItemDetails AS (
    SELECT 
        lo.l_orderkey,
        COUNT(*) AS total_lines,
        SUM(lo.l_extendedprice) AS total_extended_price,
        MAX(lo.l_discount) AS max_discount
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    sp.supplier_info,
    co.c_name,
    co.o_orderkey,
    co.o_orderstatus,
    co.o_totalprice,
    co.order_info,
    lid.total_lines,
    lid.total_extended_price,
    lid.max_discount
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.p_name LIKE '%widget%'
JOIN 
    LineItemDetails lid ON co.o_orderkey = lid.l_orderkey
WHERE 
    sp.ps_availqty > 100
ORDER BY 
    lid.total_extended_price DESC;

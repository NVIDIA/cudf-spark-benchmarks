
WITH  OrderedParts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS supplier_cost,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        op.o_orderkey,
        op.total_price
    FROM 
        OrderedParts op
    WHERE 
        op.total_price > (SELECT AVG(total_price) FROM OrderedParts)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(sp.supplier_cost, 0) AS supplier_cost,
    COALESCE(co.order_count, 0) AS customer_order_count,
    CASE 
        WHEN co.order_count IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COUNT(DISTINCT h.o_orderkey) AS high_value_orders_count
FROM 
    part p
LEFT JOIN 
    SupplierPart sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerOrders co ON p.p_partkey = co.c_custkey
LEFT JOIN 
    HighValueOrders h ON p.p_partkey = h.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, sp.supplier_cost, co.order_count
ORDER BY 
    supplier_cost DESC, customer_order_count DESC, high_value_orders_count DESC;

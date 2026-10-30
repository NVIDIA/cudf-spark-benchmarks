
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ExtendedLineItem AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_position
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    es.item_position,
    es.l_extendedprice * (1 - es.l_discount) AS final_price,
    cs.total_spent,
    ss.total_supply_cost,
    CASE 
        WHEN cs.total_orders > 5 THEN 'Regular Customer'
        ELSE 'Occasional Customer'
    END AS customer_type
FROM 
    CustomerOrders cs
JOIN 
    ExtendedLineItem es ON cs.c_custkey = es.l_orderkey
LEFT JOIN 
    SupplierStats ss ON es.l_suppkey = ss.s_suppkey
WHERE 
    ss.total_supply_cost IS NOT NULL
ORDER BY 
    customer_name, supplier_name, item_position;

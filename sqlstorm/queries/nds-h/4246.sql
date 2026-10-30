WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderAggregates AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(oa.total_order_value) AS total_spent,
        COUNT(oa.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        OrderAggregates oa ON c.c_custkey = oa.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    cs.order_count,
    ss.s_name AS preferred_supplier,
    ss.total_available_qty,
    ss.avg_supply_cost
FROM 
    CustomerPurchases cs
LEFT JOIN 
    SupplierStats ss ON cs.order_count > 0 
                    AND ss.total_available_qty = (
                        SELECT MAX(total_available_qty) 
                        FROM SupplierStats 
                        WHERE total_available_qty IS NOT NULL
                    )
WHERE 
    cs.total_spent >(
        SELECT AVG(total_spent) FROM CustomerPurchases WHERE total_spent IS NOT NULL
    )
ORDER BY 
    cs.total_spent DESC;

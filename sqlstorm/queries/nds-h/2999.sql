WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueDeliveries AS (
    SELECT 
        l.l_orderkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey, l.l_suppkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    ss.s_name,
    ss.parts_supplied,
    ss.total_supply_cost,
    COALESCE(hd.total_value, 0) AS high_value,
    RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
FROM 
    CustomerOrders co
LEFT JOIN 
    HighValueDeliveries hd ON co.c_custkey = hd.l_orderkey
JOIN 
    SupplierStats ss ON hd.l_suppkey = ss.s_suppkey
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders) 
    AND ss.total_supply_cost > (SELECT SUM(ps_supplycost) FROM partsupp) / (SELECT COUNT(DISTINCT ps_suppkey) FROM partsupp)
ORDER BY 
    co.total_spent DESC, ss.total_supply_cost ASC
LIMIT 100 OFFSET 0;
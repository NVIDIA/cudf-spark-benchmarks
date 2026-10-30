WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name 
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (
            SELECT AVG(total_spent) FROM CustomerOrders
        )
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    r.r_name AS region_name,
    SUM(l.l_quantity) AS total_quantity_sold,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    CASE 
        WHEN ss.avg_supply_cost IS NULL THEN 'No Supplier Data'
        ELSE CONCAT('Cost: ', ss.avg_supply_cost)
    END AS supplier_cost_info
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
    AND EXISTS (
        SELECT 1 
        FROM HighValueCustomers hvc 
        WHERE hvc.c_custkey = o.o_custkey
    )
GROUP BY 
    ps.ps_partkey, p.p_name, r.r_name, ss.avg_supply_cost
ORDER BY 
    total_quantity_sold DESC, avg_price_after_discount DESC
LIMIT 100;

WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
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
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    ss.s_suppkey,
    ss.s_name,
    ss.total_parts,
    ss.total_supply_cost,
    co.total_orders,
    co.total_spent,
    la.net_revenue,
    la.avg_quantity
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    CustomerOrders co ON ss.total_parts = co.total_orders
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey = co.total_orders
WHERE 
    ss.total_supply_cost > (SELECT AVG(ss2.total_supply_cost) FROM SupplierStats ss2)
    OR co.total_spent < 1000
ORDER BY 
    co.c_name, ss.s_name;

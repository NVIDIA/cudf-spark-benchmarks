
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_linenumber) AS total_items
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    ss.s_name,
    ss.total_parts,
    ss.total_supply_cost,
    COALESCE(LOS.total_items, 0) AS total_items_ordered,
    COALESCE(LOS.net_revenue, 0) AS total_revenue,
    cs.total_spent
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON MOD(cs.c_custkey, 10) = MOD(ss.s_suppkey, 10) 
LEFT JOIN 
    LineItemSummary LOS ON cs.order_count = LOS.total_items 
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders) 
    AND ss.total_supply_cost IS NOT NULL
ORDER BY 
    cs.total_spent DESC
LIMIT 100;

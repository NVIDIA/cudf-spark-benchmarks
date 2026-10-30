
WITH SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    sp.s_suppkey,
    sp.s_name,
    COALESCE(ls.net_revenue, 0) AS net_revenue,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost
FROM 
    CustomerOrders cs
FULL OUTER JOIN 
    SupplierPart sp ON cs.c_custkey = sp.s_suppkey
LEFT JOIN 
    LineItemStats ls ON ls.l_orderkey = cs.c_custkey
WHERE 
    (cs.total_orders > 5 OR sp.total_supply_cost > 1000)
    AND (sp.s_name IS NOT NULL OR cs.c_name IS NOT NULL)
ORDER BY 
    cs.total_spent DESC,
    sp.total_supply_cost DESC;

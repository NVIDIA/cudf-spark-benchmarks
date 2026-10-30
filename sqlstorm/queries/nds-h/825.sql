WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
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
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    r.r_name AS region,
    COUNT(DISTINCT ns.n_nationkey) AS total_nations,
    SUM(ss.total_parts) AS total_parts_supplied,
    SUM(cs.total_orders) AS total_orders_placed,
    SUM(ol.total_lineitem_price) AS total_lineitem_revenue,
    COALESCE(SUM(ss.avg_supply_cost), 0) AS avg_supply_cost_per_supplier
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON ns.n_nationkey = cs.c_custkey
LEFT JOIN 
    OrderLineItems ol ON cs.total_orders = ol.o_orderkey
WHERE 
    r.r_name LIKE 'A%' 
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT ns.n_nationkey) > 0
ORDER BY 
    total_orders_placed DESC
LIMIT 10;
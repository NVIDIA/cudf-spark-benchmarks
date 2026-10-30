WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighRollers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierPerformance AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        (SELECT COUNT(DISTINCT l.l_orderkey) 
         FROM lineitem l 
         WHERE l.l_suppkey = ss.s_suppkey) AS order_count,
        ss.total_parts,
        ss.total_available,
        ss.avg_supply_cost,
        COALESCE(h.total_spent, 0) AS high_roller_spend
    FROM 
        SupplierStats ss
    LEFT JOIN 
        HighRollers h ON ss.s_suppkey = h.c_custkey
)
SELECT 
    sp.s_name,
    sp.order_count,
    sp.total_parts,
    sp.total_available,
    sp.avg_supply_cost,
    sp.high_roller_spend,
    ROW_NUMBER() OVER (ORDER BY sp.avg_supply_cost DESC) AS rank
FROM 
    SupplierPerformance sp
WHERE 
    sp.total_available > 100
ORDER BY 
    sp.avg_supply_cost DESC
LIMIT 10;

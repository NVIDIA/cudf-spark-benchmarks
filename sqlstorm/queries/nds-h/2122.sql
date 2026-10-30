
WITH RankedSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey, s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        r.r_name AS region
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
),
HighSpenders AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_orders,
        cust.total_spent,
        CASE 
            WHEN cust.total_spent > 1000 THEN 'High'
            ELSE 'Low'
        END AS spender_category
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent IS NOT NULL
)
SELECT 
    ns.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(hs.c_name, 'No Customers') AS customer_name,
    COALESCE(hs.total_spent, 0) AS total_spending,
    COALESCE(ranked.total_supply_cost, 0) AS total_supply_cost,
    hs.spender_category
FROM 
    nation ns
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighSpenders hs ON ns.n_nationkey = hs.c_custkey
LEFT JOIN 
    RankedSuppliers ranked ON ns.n_nationkey = ranked.s_nationkey
WHERE 
    (hs.total_spent IS NOT NULL OR ranked.total_supply_cost IS NOT NULL)
ORDER BY 
    ns.n_name, r.r_name, total_spending DESC;

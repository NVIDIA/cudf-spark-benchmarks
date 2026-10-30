WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OutstandingOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) as total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND EXISTS (
            SELECT 1 
            FROM lineitem l2 
            WHERE l2.l_orderkey = o.o_orderkey 
            AND l2.l_returnflag = 'R'
        )
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        CASE 
            WHEN SUM(o.o_totalprice) > 1000 THEN 'Platinum' 
            ELSE 'Standard' 
        END AS customer_tier
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey
)

SELECT 
    cs.c_custkey,
    cs.total_spent,
    cs.total_orders,
    cs.customer_tier,
    rs.s_name,
    rs.total_supply_cost,
    CASE 
        WHEN cs.total_orders > 5 THEN 'Frequent Buyer' 
        ELSE 'Casual Buyer' 
    END AS buying_pattern,
    (CASE 
        WHEN cs.customer_tier = 'Platinum' AND rs.rank = 1 THEN 'VIP Supply'
        ELSE 'Regular Supply' 
    END) as supply_type,
    RANK() OVER (PARTITION BY cs.customer_tier ORDER BY cs.total_spent DESC) as spending_rank
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey
WHERE 
    cs.total_spent IS NOT NULL 
    AND cs.total_orders > 0
ORDER BY 
    cs.customer_tier, cs.total_spent DESC
LIMIT 10;

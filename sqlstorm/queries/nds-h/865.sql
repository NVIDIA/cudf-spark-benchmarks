WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    cs.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    ss.total_available,
    ss.total_supply_cost,
    ld.revenue,
    ld.returned_quantity
FROM 
    CustomerOrderStats cs
FULL OUTER JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey 
LEFT JOIN 
    LineitemDetails ld ON ld.l_orderkey = cs.c_custkey
WHERE 
    (cs.order_count IS NULL OR cs.total_spent >= 1000)
    AND (ss.total_available IS NOT NULL AND ss.total_supply_cost > 500)
ORDER BY 
    cs.total_spent DESC NULLS LAST, 
    ss.total_supply_cost DESC NULLS LAST;

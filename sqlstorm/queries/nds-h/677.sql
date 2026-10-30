
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
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
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    co.c_name,
    co.total_orders,
    co.total_spent,
    rs.s_name AS top_supplier
FROM 
    PartStats ps
LEFT JOIN 
    CustomerOrders co ON ps.p_partkey = (SELECT ps_partkey 
                                            FROM partsupp 
                                            WHERE ps_availqty > 0 
                                            ORDER BY ps_supplycost 
                                            LIMIT 1)  -- Standard SQL for LIMIT
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
WHERE 
    ps.total_available > 0 
    AND co.total_spent IS NOT NULL
ORDER BY 
    ps.avg_supply_cost DESC, 
    co.total_spent DESC;

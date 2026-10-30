WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name,
    COALESCE(ss.total_available_qty, 0) AS total_available_qty,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value
FROM 
    nation ns
LEFT JOIN 
    SupplierSummary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrderDetails cs ON ns.n_nationkey = cs.c_custkey
WHERE 
    (ss.parts_supplied > 10 OR cs.total_orders IS NOT NULL)
ORDER BY 
    ns.n_name;

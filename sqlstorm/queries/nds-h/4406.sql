WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    COALESCE(rs.total_supply_cost, 0) AS supplier_total_cost,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrderSummary cs ON cs.c_custkey = (
        SELECT c.c_custkey 
        FROM CustomerOrderSummary c 
        WHERE c.order_rank <= 10 
        ORDER BY c.total_spent DESC 
        LIMIT 1 
    )
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE 
    (cs.total_spent > 1000 OR rs.total_supply_cost > 50000) 
    AND rs.supply_rank = 1
ORDER BY 
    region_name, nation_name, customer_name;
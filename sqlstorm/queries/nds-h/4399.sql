WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_parts,
        ss.total_available,
        ss.avg_supply_cost,
        RANK() OVER (ORDER BY ss.total_available DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_parts > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.total_orders,
    c.total_spent,
    c.avg_order_value,
    COALESCE(ts.total_available, 0) AS supplier_total_available,
    COALESCE(ts.avg_supply_cost, 0) AS supplier_avg_cost
FROM 
    CustomerOrders c
LEFT JOIN 
    TopSuppliers ts ON c.c_custkey = ts.s_suppkey
WHERE 
    c.order_rank <= 3 
    AND c.total_orders > 0
ORDER BY 
    c.total_spent DESC, c.c_custkey;

WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s_stats.total_supply_cost,
        s_stats.part_count,
        RANK() OVER (ORDER BY s_stats.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierStats s_stats
    JOIN 
        supplier s ON s_stats.s_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cu.c_name AS customer_name,
    cu.order_count,
    cu.total_spent,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost
FROM 
    CustomerOrders cu
JOIN 
    TopSuppliers ts ON ts.supplier_rank <= 10
WHERE 
    cu.total_spent > 10000
ORDER BY 
    cu.total_spent DESC, ts.total_supply_cost DESC;

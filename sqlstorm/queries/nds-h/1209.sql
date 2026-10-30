
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_avail_qty,
        sp.total_supply_cost
    FROM 
        SupplierParts sp
    WHERE 
        sp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierParts)
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
    HAVING 
        COUNT(o.o_orderkey) > 0
),
FinalReport AS (
    SELECT 
        cu.c_custkey,
        cu.c_name,
        COALESCE(s.s_name, 'No Supplier') AS supplier_name,
        cu.total_orders,
        cu.total_spent,
        COALESCE(s.total_avail_qty, 0) AS supplier_availability,
        ROW_NUMBER() OVER (PARTITION BY cu.c_custkey ORDER BY cu.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders cu
    LEFT JOIN 
        HighValueSuppliers s ON cu.c_custkey = s.s_suppkey
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.supplier_name,
    f.total_orders,
    f.total_spent,
    f.supplier_availability,
    CASE 
        WHEN f.customer_rank IS NULL THEN 'No Ranking'
        ELSE CAST(f.customer_rank AS STRING)
    END AS customer_rank
FROM 
    FinalReport f
WHERE 
    f.total_spent > 1000
ORDER BY 
    f.total_spent DESC, 
    f.c_name;

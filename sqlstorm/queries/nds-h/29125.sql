WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    si.s_name AS supplier_name,
    si.nation AS supplier_nation,
    si.total_parts AS parts_supplied,
    si.total_supplycost AS total_supply_cost,
    co.c_name AS customer_name,
    co.total_orders AS total_orders_placed,
    co.total_spent AS total_spent_by_customer
FROM 
    SupplierInfo si
JOIN 
    CustomerOrders co ON si.total_parts = (SELECT MAX(total_parts) FROM SupplierInfo)
WHERE 
    si.total_supplycost > 10000
ORDER BY 
    co.total_spent DESC
LIMIT 10;

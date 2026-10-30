WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    S.s_name AS supplier_name,
    S.nation_name,
    C.c_name AS customer_name,
    C.total_spent,
    S.total_supply_cost
FROM 
    SupplierStats S
JOIN 
    CustomerOrders C ON S.total_supply_cost > C.total_spent
WHERE 
    S.nation_name = 'USA'
ORDER BY 
    S.total_supply_cost DESC, C.total_spent DESC
LIMIT 10;

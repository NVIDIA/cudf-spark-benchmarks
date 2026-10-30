WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
    HAVING 
        COUNT(l.l_orderkey) > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS supplier,
    p.p_name AS part,
    p.p_brand,
    c.c_name AS customer,
    c.total_spent,
    s.total_supply_cost,
    p.order_count
FROM 
    SupplierStats s
JOIN 
    PopularParts p ON s.total_parts_supplied > 5
JOIN 
    CustomerOrders c ON c.total_orders > 10
WHERE 
    s.total_supply_cost > 10000
ORDER BY 
    s.total_supply_cost DESC, c.total_spent DESC
LIMIT 50;

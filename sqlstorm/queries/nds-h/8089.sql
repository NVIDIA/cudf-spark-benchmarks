WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PopularProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_sold DESC
    LIMIT 5
)
SELECT 
    co.c_name AS customer_name,
    co.total_spent,
    sp.s_name AS supplier_name,
    sp.total_supply_cost,
    pp.p_name AS product_name,
    pp.total_sold
FROM 
    CustomerOrders co
JOIN 
    SupplierParts sp ON co.order_count > 10
JOIN 
    PopularProducts pp ON pp.total_sold > 100
ORDER BY 
    co.total_spent DESC, 
    sp.total_supply_cost ASC;
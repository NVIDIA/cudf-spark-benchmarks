WITH HighValueSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        SUM(ps_supplycost * ps_availqty) AS total_supply_value
    FROM 
        supplier 
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY 
        s_suppkey, s_name 
    HAVING 
        SUM(ps_supplycost * ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        total_orders,
        RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM 
        CustomerOrders c
    WHERE 
        total_orders > 5000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(hs.total_supply_value, 0) AS total_supply_value,
    tc.c_name AS top_customer,
    tc.total_orders,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category
FROM 
    part p
LEFT JOIN 
    HighValueSuppliers hs ON p.p_partkey = hs.s_suppkey 
LEFT JOIN 
    TopCustomers tc ON tc.order_rank <= 3
WHERE 
    p.p_size IN (SELECT DISTINCT ps_availqty FROM partsupp WHERE ps_supplycost < 20)
ORDER BY 
    total_supply_value DESC, 
    p.p_name ASC;

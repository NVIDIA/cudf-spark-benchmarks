
WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name AS cust_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1995-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        MIN(ps.ps_supplycost) AS minimum_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
MaxOrder AS (
    SELECT 
        cust.c_custkey,
        MAX(cust.total_spent) AS max_spent
    FROM 
        CustomerOrders cust
    GROUP BY 
        cust.c_custkey
)
SELECT 
    co.cust_name,
    po.p_name,
    po.total_available_quantity,
    po.minimum_supply_cost,
    co.total_orders,
    co.total_spent,
    CASE 
        WHEN co.total_spent >= mo.max_spent THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_category
FROM 
    CustomerOrders co
JOIN 
    MaxOrder mo ON co.c_custkey = mo.c_custkey
JOIN 
    PartSupplier po ON co.c_custkey = po.p_partkey 
WHERE 
    po.total_available_quantity IS NOT NULL
ORDER BY 
    co.total_spent DESC, po.p_name ASC
LIMIT 100;

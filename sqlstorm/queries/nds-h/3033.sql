WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        cs.c_custkey, 
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats) 
    ORDER BY 
        cs.total_spent DESC
    LIMIT 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sp.total_available_quantity, 0) AS available_quantity,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN toc.total_spending IS NULL THEN 'No Orders'
        ELSE CONCAT('Spent: $', ROUND(toc.total_spending, 2))
    END AS customer_order_info
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    (SELECT 
        o.o_custkey, 
        SUM(o.o_totalprice) AS total_spending 
     FROM 
        orders o 
     JOIN 
        TopCustomers tc ON o.o_custkey = tc.c_custkey 
     GROUP BY 
        o.o_custkey) toc ON toc.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'A%')
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size > 10)
ORDER BY 
    p.p_brand,
    p.p_name;
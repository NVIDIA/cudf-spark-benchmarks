
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
DiscountedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_total
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        l.l_orderkey
),
MaxTotalSpent AS (
    SELECT 
        MAX(total_spent) AS max_spent
    FROM 
        CustomerOrders
    WHERE 
        order_count > 5
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.total_supply_cost
    FROM 
        SupplierParts sp
    WHERE 
        sp.rank <= 5
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    ts.total_supply_cost,
    ds.discounted_total
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN 
        (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
        LIMIT 1)
LEFT JOIN 
    DiscountedSales ds ON ds.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice = (SELECT max_spent FROM MaxTotalSpent))
WHERE 
    co.total_spent IS NOT NULL 
    AND ts.total_supply_cost IS NOT NULL
    AND (co.total_spent > COALESCE(ds.discounted_total, 0) OR ds.discounted_total IS NULL)
ORDER BY 
    co.total_spent DESC
LIMIT 10;

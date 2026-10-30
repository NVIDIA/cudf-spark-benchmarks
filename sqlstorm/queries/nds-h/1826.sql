
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders c
    WHERE 
        total_orders > 5
)

SELECT 
    sp.s_name,
    sp.total_available,
    sp.average_supply_cost,
    tc.c_name AS top_customer
FROM 
    SupplierParts sp
FULL OUTER JOIN 
    TopCustomers tc ON sp.s_suppkey = tc.c_custkey
WHERE 
    (sp.total_available IS NOT NULL AND sp.average_supply_cost > 10.00) OR 
    (tc.rank <= 5 AND tc.c_custkey IS NOT NULL)
ORDER BY 
    sp.total_available DESC, 
    tc.rank;

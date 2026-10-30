
WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (
            SELECT 
                AVG(c2.c_acctbal) 
            FROM 
                customer c2
        )
),
TopOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice
    FROM 
        orders o
    ORDER BY 
        o.o_totalprice DESC
    LIMIT 10
),
LineItemsWithSupplier AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_quantity, 
        l.l_extendedprice,
        s.s_name AS supplier_name
    FROM 
        lineitem l
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
)
SELECT 
    hvc.c_custkey, 
    hvc.c_name, 
    SUM(li.l_extendedprice) AS total_spent, 
    sc.total_cost AS supplier_cost
FROM 
    HighValueCustomers hvc
JOIN 
    orders o ON hvc.c_custkey = o.o_custkey
JOIN 
    LineItemsWithSupplier li ON o.o_orderkey = li.l_orderkey
JOIN 
    SupplierCost sc ON li.l_suppkey = sc.s_suppkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    hvc.c_custkey, hvc.c_name, sc.total_cost
HAVING 
    SUM(li.l_extendedprice) > (SELECT AVG(l_extendedprice) FROM lineitem)
ORDER BY 
    total_spent DESC;

WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate < o.o_orderdate + INTERVAL '30 day'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY SUM(ho.net_order_value) DESC) AS rank
    FROM 
        customer c
    JOIN 
        HighValueOrders ho ON c.c_custkey = ho.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    TC.c_name AS customer_name,
    SUM(ho.net_order_value) AS total_spent,
    COUNT(ho.o_orderkey) AS total_orders
FROM 
    TopCustomers TC
LEFT JOIN 
    HighValueOrders ho ON TC.c_custkey = ho.o_custkey
LEFT JOIN 
    RankedSuppliers RS ON TC.c_custkey = RS.s_suppkey
JOIN 
    nation n ON TC.c_custkey = n.n_nationkey
WHERE 
    n.n_regionkey IS NOT NULL
GROUP BY 
    n.n_name, RS.s_name, TC.c_name
HAVING 
    SUM(ho.net_order_value) > 1000 OR RS.s_name IS NULL
ORDER BY 
    n.n_name, total_spent DESC
LIMIT 10;

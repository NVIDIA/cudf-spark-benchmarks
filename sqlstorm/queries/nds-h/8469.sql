
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_cost DESC
    LIMIT 10
), 
CustomerRevenues AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ro.total_revenue) AS total_customer_revenue
    FROM 
        customer AS c
    JOIN 
        RankedOrders AS ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(ro.total_revenue) > 100000
)
SELECT 
    cr.c_name, 
    cr.total_customer_revenue, 
    ts.s_name, 
    ts.total_cost
FROM 
    CustomerRevenues AS cr
JOIN 
    TopSuppliers AS ts ON cr.c_custkey = ts.s_suppkey
ORDER BY 
    cr.total_customer_revenue DESC, ts.total_cost ASC
LIMIT 20;

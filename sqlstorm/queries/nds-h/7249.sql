
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ts.s_nationkey, 
        n.n_name AS nation_name, 
        ts.s_suppkey, 
        ts.s_name, 
        ts.total_cost
    FROM 
        RankedSuppliers ts
    JOIN 
        nation n ON ts.s_nationkey = n.n_nationkey
    WHERE 
        ts.rank <= 5
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_mktsegment
)
SELECT 
    t.nation_name,
    SUM(co.revenue) AS total_revenue,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    COUNT(DISTINCT co.c_custkey) AS total_customers
FROM 
    TopSuppliers t
JOIN 
    CustomerOrders co ON t.s_suppkey = co.c_custkey
GROUP BY 
    t.nation_name
ORDER BY 
    total_revenue DESC;

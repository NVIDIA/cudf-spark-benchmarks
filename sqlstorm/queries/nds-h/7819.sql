
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey, s.s_name
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    SUM(ro.total_revenue) AS total_revenue,
    SUM(ts.supplier_cost) AS total_supplier_cost
FROM 
    RankedOrders ro
JOIN 
    customer co ON ro.o_orderkey = co.c_custkey
JOIN 
    nation n ON co.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON ts.ps_suppkey = co.c_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;

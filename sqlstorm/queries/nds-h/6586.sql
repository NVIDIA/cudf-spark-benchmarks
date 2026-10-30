
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS nation_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    tn.n_name AS top_nation,
    ts.s_name AS top_supplier
FROM 
    RankedOrders ro
JOIN 
    TopNations tn ON ro.total_revenue = (SELECT MAX(nation_revenue) FROM TopNations)
JOIN 
    TopSuppliers ts ON ts.supplier_cost = (SELECT MAX(supplier_cost) FROM TopSuppliers)
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    ro.total_revenue DESC;

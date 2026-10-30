WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_container = 'SM CASE' 
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_cost DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(lo.total_revenue) AS total_sales,
    SUM(ts.total_cost) AS total_supplier_cost
FROM 
    RankedOrders lo
JOIN 
    orders o ON lo.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON ts.ps_suppkey = o.o_custkey
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(lo.total_revenue) > 1000000
ORDER BY 
    total_sales DESC;
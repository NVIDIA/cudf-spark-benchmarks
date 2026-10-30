
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        s.s_name AS supplier_name,
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, s.s_name, l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.supplier_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank = 1
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.total_revenue,
    RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
FROM 
    TopSuppliers r
ORDER BY 
    r.total_revenue DESC;

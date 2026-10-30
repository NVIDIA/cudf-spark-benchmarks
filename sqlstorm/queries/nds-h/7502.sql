WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
        AND l.l_shipdate < DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
),
FinalResults AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.r_name,
        ts.total_revenue,
        rs.total_cost,
        ts.total_revenue / rs.total_cost AS revenue_cost_ratio
    FROM 
        TopSuppliers ts
    JOIN 
        RankedSuppliers rs ON ts.s_suppkey = rs.s_suppkey
)
SELECT 
    f.s_suppkey,
    f.s_name,
    f.r_name,
    f.total_revenue,
    f.total_cost,
    f.revenue_cost_ratio
FROM 
    FinalResults f
ORDER BY 
    f.revenue_cost_ratio DESC
LIMIT 10;
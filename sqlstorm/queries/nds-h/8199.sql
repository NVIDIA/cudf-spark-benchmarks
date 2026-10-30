WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
), TotalRevenue AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    COALESCE(tr.revenue, 0) AS revenue,
    r.total_cost,
    r.rank 
FROM 
    RankedSuppliers r 
LEFT JOIN 
    TotalRevenue tr ON r.s_suppkey = tr.l_suppkey
WHERE 
    r.rank <= 5
ORDER BY 
    r.rank, revenue DESC;
WITH RevenueBySupplier AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_name
), 
TopSuppliers AS (
    SELECT 
        supplier_name, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS rank
    FROM 
        RevenueBySupplier
)
SELECT 
    t.supplier_name, 
    t.total_revenue,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    TopSuppliers t
JOIN 
    supplier s ON t.supplier_name = s.s_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_revenue DESC;
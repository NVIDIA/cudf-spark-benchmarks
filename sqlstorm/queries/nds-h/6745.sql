WITH SupplierLineItem AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue,
        SUM(l.l_discount) AS total_discounted_price,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierLineItem s
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.total_quantity,
    rs.total_revenue,
    rs.total_discounted_price,
    rs.order_count
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    r.r_name, n.n_name, rs.total_revenue DESC;
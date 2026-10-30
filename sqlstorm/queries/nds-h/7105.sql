WITH calculated AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        s.s_name AS supplier_name,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, n.n_name
), ranked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        calculated
)
SELECT 
    r.nation_name, 
    r.supplier_name, 
    SUM(r.total_quantity) AS total_quantity_sold, 
    SUM(r.total_revenue) AS total_revenue_generated
FROM 
    ranked r
WHERE 
    r.revenue_rank <= 5
GROUP BY 
    r.nation_name, r.supplier_name
ORDER BY 
    r.nation_name, total_revenue_generated DESC;
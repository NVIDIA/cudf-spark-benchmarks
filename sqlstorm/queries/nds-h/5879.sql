
WITH Revenue AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
), 
NationRanked AS (
    SELECT 
        nation_name, 
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        Revenue
)
SELECT 
    r.r_name AS region_name,
    nr.nation_name,
    nr.total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationRanked nr ON n.n_name = nr.nation_name
WHERE 
    nr.revenue_rank <= 10
ORDER BY 
    r.r_name, nr.total_revenue DESC;

WITH RevenueByNation AS (
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
), TopNations AS (
    SELECT 
        nation_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS rank
    FROM 
        RevenueByNation
)
SELECT 
    t.nation_name,
    t.total_revenue,
    s.s_name AS top_supplier,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    TopNations t
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size < 20)
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    t.rank <= 5
GROUP BY 
    t.nation_name, t.total_revenue, s.s_name
ORDER BY 
    t.total_revenue DESC;
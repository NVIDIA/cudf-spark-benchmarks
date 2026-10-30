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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
), 
PartRevenue AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
), 
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pr.part_revenue
    FROM 
        PartRevenue pr
    JOIN 
        part p ON pr.p_partkey = p.p_partkey
    ORDER BY 
        pr.part_revenue DESC
    LIMIT 10
)
SELECT 
    r.nation_name,
    tp.p_name,
    tp.part_revenue
FROM 
    Revenue r
JOIN 
    TopParts tp ON r.nation_name = 'FRANCE'
ORDER BY 
    tp.part_revenue DESC;
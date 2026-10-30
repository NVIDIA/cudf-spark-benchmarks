WITH RankedItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ls.l_extendedprice * (1 - ls.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem ls ON p.p_partkey = ls.l_partkey
    JOIN 
        orders o ON ls.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON ls.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'EUROPE' 
        AND o.o_orderdate >= '1996-01-01' 
        AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), TopItems AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        revenue
    FROM 
        RankedItems
    WHERE 
        rank <= 5
)
SELECT 
    t.p_partkey,
    t.p_name,
    t.p_brand,
    t.revenue,
    COUNT(n.n_nationkey) AS supplier_count
FROM 
    TopItems t
JOIN 
    partsupp ps ON t.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    t.p_partkey, t.p_name, t.p_brand, t.revenue
ORDER BY 
    t.revenue DESC;
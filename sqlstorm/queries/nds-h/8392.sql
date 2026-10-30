WITH RankedItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(ri.total_revenue) AS total_region_revenue,
    COUNT(DISTINCT ri.p_partkey) AS distinct_parts_count
FROM 
    RankedItems ri
JOIN 
    supplier s ON ri.ps_supplycost = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ri.rank <= 5
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_region_revenue DESC;
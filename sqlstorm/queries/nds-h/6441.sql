WITH supplier_total_cost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
part_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    p.p_name AS part,
    pc.total_sales,
    stc.total_cost,
    (pc.total_sales - stc.total_cost) AS profit_margin
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    part_sales pc ON p.p_partkey = pc.p_partkey
JOIN 
    supplier_total_cost stc ON s.s_suppkey = stc.s_suppkey
WHERE 
    (pc.total_sales - stc.total_cost) > 0
ORDER BY 
    profit_margin DESC
LIMIT 50;
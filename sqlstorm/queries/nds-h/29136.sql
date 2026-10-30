WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT l.l_orderkey) DESC) AS popularity_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    n.n_name AS nation_name,
    pp.p_partkey,
    pp.p_name,
    pp.order_count,
    rs.total_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
JOIN 
    PopularParts pp ON rs.rank = 1
WHERE 
    rs.total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
ORDER BY 
    pp.order_count DESC, rs.total_cost DESC;

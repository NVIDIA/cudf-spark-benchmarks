WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size >= 10
        AND s.s_acctbal > 0.00
        AND p.p_comment LIKE '%special%'
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.nation_name,
    rs.p_name,
    rs.ps_availqty,
    rs.ps_supplycost
FROM 
    RankedSuppliers rs
WHERE 
    rs.rank <= 3
ORDER BY 
    rs.p_name, rs.ps_supplycost DESC;

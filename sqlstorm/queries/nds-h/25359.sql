WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(p.p_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_comment LIKE '%quality%'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),

TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_available_quantity,
        rs.total_parts, 
        n.n_name AS nation_name 
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
)

SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    ts.total_available_quantity, 
    ts.total_parts, 
    ts.nation_name,
    CONCAT(ts.s_name, ' from ', ts.nation_name) AS supplier_info
FROM 
    TopSuppliers ts
ORDER BY 
    ts.total_available_quantity DESC;

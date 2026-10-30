WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
)
SELECT 
    rs.s_name,
    rs.nation_name,
    rs.order_count,
    rs.total_revenue,
    SUBSTRING(rs.s_name, 1, 10) AS short_name,
    CONCAT('Supplier: ', rs.s_name, ' from ', rs.nation_name) AS detailed_info
FROM 
    RankedSuppliers rs
WHERE 
    rs.rnk <= 5
ORDER BY 
    rs.nation_name, rs.total_revenue DESC;

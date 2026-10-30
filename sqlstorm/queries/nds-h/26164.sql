WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        CONCAT(p.p_name, ' - ', p.p_comment) AS full_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00 AND 
        p.p_size < 30
)
SELECT 
    r.r_name AS region,
    f.full_description,
    rs.s_name AS supplier_name,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount
FROM 
    FilteredParts f
JOIN 
    lineitem l ON f.p_partkey = l.l_partkey
JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.rank <= 3
GROUP BY 
    r.r_name, f.full_description, rs.s_name
ORDER BY 
    r.r_name, avg_price_after_discount DESC;

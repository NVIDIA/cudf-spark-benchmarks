
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.nation_name 
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank <= 3
), StringBenchmark AS (
    SELECT 
        p.p_name,
        CONCAT(s.s_name, ' from ', fs.nation_name) AS supplier_info,
        REPLACE(p.p_comment, 'a', '@') AS modified_comment
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        FilteredSuppliers fs ON fs.s_suppkey = l.l_suppkey
    JOIN 
        supplier s ON fs.s_suppkey = s.s_suppkey
)
SELECT 
    COUNT(*) AS total_records,
    AVG(CHAR_LENGTH(supplier_info)) AS avg_supplier_length,
    MIN(LENGTH(modified_comment)) AS min_comment_length,
    MAX(LENGTH(modified_comment)) AS max_comment_length
FROM 
    StringBenchmark
WHERE 
    CHAR_LENGTH(modified_comment) > 15;

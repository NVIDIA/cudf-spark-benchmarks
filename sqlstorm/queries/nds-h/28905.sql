WITH String_Benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Supplier: ', s.s_name, ' | Price: ', CAST(l.l_extendedprice AS varchar(20)), 
               ' | Nation: ', n.n_name, ' | Order Date: ', CAST(o.o_orderdate AS varchar(10)), 
               ' | Comment: ', p.p_comment) AS descriptive_info,
        LENGTH(CONCAT('Supplier: ', s.s_name, ' | Price: ', CAST(l.l_extendedprice AS varchar(20)), 
                      ' | Nation: ', n.n_name, ' | Order Date: ', CAST(o.o_orderdate AS varchar(10)), 
                      ' | Comment: ', p.p_comment)) AS info_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        LENGTH(p.p_name) > 10
      AND 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    AVG(info_length) AS avg_length,
    MAX(info_length) AS max_length,
    MIN(info_length) AS min_length,
    COUNT(*) AS total_entries
FROM 
    String_Benchmark;
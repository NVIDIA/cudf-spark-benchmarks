WITH StringProcessing AS (
    SELECT 
        p.p_name,
        s.s_name,
        c.c_name,
        CONCAT(
            'Part Name: ', p.p_name, 
            ', Supplier Name: ', s.s_name, 
            ', Customer Name: ', c.c_name, 
            ', Order Date: ', CAST(o.o_orderdate AS STRING), 
            ', Price: $', CAST(o.o_totalprice AS STRING)
        ) AS full_description,
        LENGTH(CONCAT(
            'Part Name: ', p.p_name, 
            ', Supplier Name: ', s.s_name, 
            ', Customer Name: ', c.c_name, 
            ', Order Date: ', CAST(o.o_orderdate AS STRING), 
            ', Price: $', CAST(o.o_totalprice AS STRING)
        )) AS description_length
    FROM 
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_size > 10
        AND o.o_orderdate >= DATE '1997-01-01'
)
SELECT 
    full_description, 
    description_length 
FROM 
    StringProcessing 
ORDER BY 
    description_length DESC
LIMIT 100;
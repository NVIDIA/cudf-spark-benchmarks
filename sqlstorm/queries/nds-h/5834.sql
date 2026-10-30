WITH RankedSales AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_name, p.p_name, p.p_partkey
)
SELECT 
    supplier_name,
    part_name,
    total_quantity,
    total_sales
FROM 
    RankedSales
WHERE 
    rank <= 5
ORDER BY 
    part_name, total_sales DESC;
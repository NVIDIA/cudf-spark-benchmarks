WITH PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderdate,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        r.r_name AS region_name
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
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        LOWER(p.p_comment) LIKE '%special%'
    AND 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    region_name,
    COUNT(DISTINCT customer_name) AS unique_customers,
    SUM(l_quantity) AS total_quantity,
    AVG(l_extendedprice) AS avg_price,
    SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
    COUNT(CASE WHEN l_returnflag = 'R' THEN 1 END) AS total_returns,
    COUNT(CASE WHEN l_linestatus = 'O' THEN 1 END) AS total_open_lines
FROM 
    PartDetail
GROUP BY 
    region_name
ORDER BY 
    total_sales DESC
LIMIT 10;
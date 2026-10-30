
WITH  region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
), filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.region_name,
    COALESCE(SUM(fs.order_total), 0) AS total_sales,
    COUNT(DISTINCT fs.o_orderkey) AS order_count
FROM 
    region_sales r
LEFT JOIN 
    filtered_orders fs ON r.region_name LIKE '%' || fs.o_orderdate || '%'
GROUP BY 
    r.region_name
HAVING 
    COALESCE(SUM(fs.order_total), 0) > (SELECT AVG(total_sales) FROM region_sales)
UNION ALL
SELECT 
    'Grand Total' AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
ORDER BY 
    region_name;

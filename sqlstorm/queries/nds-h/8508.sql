WITH regional_sales AS (
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
), order_priority_sales AS (
    SELECT 
        o.o_orderpriority,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_priority_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderpriority
)
SELECT 
    r.region_name,
    COALESCE(r.total_sales, 0) AS total_sales_per_region,
    COALESCE(p.total_priority_sales, 0) AS total_sales_per_priority
FROM 
    regional_sales r
FULL OUTER JOIN 
    order_priority_sales p ON r.region_name = p.o_orderpriority
ORDER BY 
    total_sales_per_region DESC, total_sales_per_priority DESC;
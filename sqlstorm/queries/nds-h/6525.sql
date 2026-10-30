
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
top_sales AS (
    SELECT 
        o.o_orderstatus,
        o.o_orderkey,
        o.o_orderdate,
        total_sales
    FROM 
        ranked_orders o
    WHERE 
        sales_rank <= 10
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS unique_customers,
    SUM(ts.total_sales) AS total_sales_by_nation
FROM 
    nation ns
JOIN 
    supplier s ON s.s_nationkey = ns.n_nationkey
JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer cs ON cs.c_custkey = o.o_custkey
JOIN 
    top_sales ts ON ts.o_orderkey = o.o_orderkey
WHERE 
    ps.ps_availqty > 0
GROUP BY 
    ns.n_name
ORDER BY 
    total_sales_by_nation DESC
LIMIT 5;

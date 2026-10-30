WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        RANKED.o_orderkey,
        RANKED.total_revenue,
        RANKED.o_orderdate
    FROM 
        RankedOrders RANKED
    WHERE 
        RANKED.order_rank <= 10
)
SELECT 
    T.o_orderkey,
    T.total_revenue,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_sold,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    AVG(l.l_discount) AS average_discount,
    SUM(l.l_tax) AS total_tax_collected
FROM 
    TopOrders T
JOIN 
    lineitem l ON T.o_orderkey = l.l_orderkey
GROUP BY 
    T.o_orderkey, T.total_revenue, T.o_orderdate
ORDER BY 
    T.total_revenue DESC;

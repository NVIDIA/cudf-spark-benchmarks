WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    JOIN 
        nation AS n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopNationSales AS (
    SELECT 
        nation_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        RankedOrders AS o
    WHERE 
        rank_order <= 10
    GROUP BY 
        nation_name
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    MAX(o.o_totalprice) AS max_order_value
FROM 
    lineitem AS l
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
WHERE 
    n.n_name IN (SELECT nation_name FROM TopNationSales)
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC, customer_count DESC;

WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 100
)
SELECT 
    tn.n_name,
    COUNT(ro.o_orderkey) AS order_rank_count,
    AVG(ro.o_totalprice) AS average_total_price
FROM 
    TopNations tn
LEFT JOIN 
    RankedOrders ro ON tn.n_name IN (
        SELECT n.n_name
        FROM nation n
    )
WHERE 
    ro.rank <= 10
GROUP BY 
    tn.n_name
ORDER BY 
    average_total_price DESC
LIMIT 5;

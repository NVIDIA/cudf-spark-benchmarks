WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
TopNations AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 100
)
SELECT 
    rn.o_orderkey, 
    rn.o_orderdate, 
    rn.o_totalprice, 
    tn.n_name AS nation_name, 
    rn.c_name AS customer_name
FROM 
    RankedOrders rn
JOIN 
    TopNations tn ON rn.o_orderkey = rn.o_orderkey
WHERE 
    rn.price_rank <= 5
ORDER BY 
    tn.order_count DESC, 
    rn.o_totalprice DESC;
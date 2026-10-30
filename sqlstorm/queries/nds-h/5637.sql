WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
TopLineItems AS (
    SELECT 
        rl.l_orderkey, 
        rl.l_partkey,
        rl.total_revenue
    FROM 
        RankedLineItems rl
    WHERE 
        rl.rank <= 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.o_totalprice,
    od.c_name,
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(tli.total_revenue) AS total_revenue
FROM 
    OrderDetails od
JOIN 
    TopLineItems tli ON od.o_orderkey = tli.l_orderkey
JOIN 
    part p ON tli.l_partkey = p.p_partkey
WHERE 
    od.o_orderdate >= '1997-01-01'
GROUP BY 
    od.o_orderkey, od.o_orderdate, od.o_totalprice, od.c_name, p.p_name, p.p_brand, p.p_type
ORDER BY 
    total_revenue DESC
LIMIT 50;
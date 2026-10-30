WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 5
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        p.p_name,
        p.p_brand
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_orderkey IN (SELECT o.o_orderkey FROM TopOrders o)
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.c_name,
    od.l_partkey,
    od.p_name,
    od.p_brand,
    SUM(od.l_quantity) AS total_quantity,
    SUM(od.l_extendedprice) AS total_revenue
FROM 
    (
        SELECT 
            t.o_orderkey,
            t.o_orderdate,
            t.c_name,
            details.l_partkey,
            details.p_name,
            details.p_brand,
            details.l_quantity,
            details.l_extendedprice
        FROM 
            TopOrders t
        JOIN 
            OrderDetails details ON t.o_orderkey = details.l_orderkey
    ) od
GROUP BY 
    od.o_orderkey, od.o_orderdate, od.c_name, od.l_partkey, od.p_name, od.p_brand
ORDER BY 
    total_revenue DESC
LIMIT 100;
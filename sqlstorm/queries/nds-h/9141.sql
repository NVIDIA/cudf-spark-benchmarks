WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
RecentOrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.c_name,
        ro.o_orderdate,
        ro.o_totalprice,
        li.l_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        li.l_quantity,
        (li.l_extendedprice * (1 - li.l_discount)) AS net_price
    FROM 
        RankedOrders ro
    JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    JOIN 
        part p ON li.l_partkey = p.p_partkey
    WHERE 
        ro.rn = 1
)
SELECT 
    rod.c_name,
    COUNT(rod.o_orderkey) AS order_count,
    SUM(rod.net_price) AS total_revenue,
    AVG(rod.o_totalprice) AS average_order_value,
    MIN(rod.o_orderdate) AS first_order_date,
    MAX(rod.o_orderdate) AS last_order_date
FROM 
    RecentOrderDetails rod
WHERE 
    rod.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    rod.c_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
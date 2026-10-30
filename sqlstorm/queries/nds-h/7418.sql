WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
), OrderDetails AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        SUM(lo.l_quantity) AS total_quantity,
        MAX(lo.l_shipmode) AS max_shipmode,
        MAX(lo.l_returnflag) AS return_flag
    FROM 
        lineitem lo
    JOIN 
        RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
    WHERE 
        lo.l_shipdate >= '1997-01-01' AND lo.l_shipdate < '1997-10-01'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT od.l_orderkey) AS order_count, 
    SUM(od.revenue) AS total_revenue, 
    AVG(od.total_quantity) AS avg_quantity, 
    MAX(od.max_shipmode) AS peak_shipmode
FROM 
    OrderDetails od
JOIN 
    supplier s ON od.l_orderkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT od.l_orderkey) > 10
ORDER BY 
    total_revenue DESC;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
HighValueLines AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
JoinCTE AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_nationkey,
        hv.high_value
    FROM RankedOrders ro
    JOIN HighValueLines hv ON ro.o_orderkey = hv.l_orderkey
    WHERE ro.order_rank <= 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT j.o_orderkey) AS order_count,
    AVG(j.high_value) AS average_high_value
FROM JoinCTE j
JOIN nation n ON j.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY order_count DESC, average_high_value DESC;

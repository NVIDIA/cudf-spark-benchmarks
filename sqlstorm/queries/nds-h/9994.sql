WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        l.l_quantity,
        l.l_extendedprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),
FilteredOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE order_rank <= 10
)
SELECT 
    fo.o_orderkey,
    fo.o_orderdate,
    fo.o_totalprice,
    fo.customer_name,
    SUM(fo.l_extendedprice) AS total_extended_price,
    COUNT(fo.l_quantity) AS total_items,
    AVG(fo.l_quantity) AS avg_quantity
FROM FilteredOrders fo
GROUP BY 
    fo.o_orderkey,
    fo.o_orderdate,
    fo.o_totalprice,
    fo.customer_name
ORDER BY 
    fo.o_orderdate DESC, 
    total_extended_price DESC;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
)
SELECT 
    r.r_name,
    count(DISTINCT c.c_custkey) AS num_customers,
    SUM(o.o_totalprice) AS total_sales,
    COUNT(DISTINCT lo.l_orderkey) AS num_line_items,
    AVG(lo.l_extendedprice) AS avg_line_item_price
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND o.o_orderstatus = 'F'
    AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC
LIMIT 5;
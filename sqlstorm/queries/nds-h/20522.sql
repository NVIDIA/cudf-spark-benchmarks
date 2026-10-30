WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(CASE WHEN ps.ps_supplycost > 100 THEN ps.ps_availqty END), 0) AS high_cost_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_total
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    n.n_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    sd.high_cost_avail_qty,
    cd.order_count,
    cd.avg_order_total,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_quantity) DESC) AS nation_rank
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
JOIN CustomerOrderDetails cd ON c.c_custkey = cd.c_custkey
WHERE l.l_returnflag = 'N'
AND sd.total_supply_cost IS NOT NULL
GROUP BY p.p_name, n.n_name, sd.high_cost_avail_qty, cd.order_count, cd.avg_order_total
HAVING SUM(l.l_quantity) > (SELECT AVG(l_qty) FROM (SELECT SUM(l_quantity) AS l_qty FROM lineitem GROUP BY l_orderkey) AS avg_quantity)
ORDER BY total_quantity DESC
LIMIT 10;


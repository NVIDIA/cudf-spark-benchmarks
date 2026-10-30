WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), HighSpenderSuppliers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchase,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        MAX(l.l_shipdate) AS last_order_date
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
    GROUP BY co.c_custkey, co.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(r.n_name, 'Unknown') AS nation_name,
    string_agg(s.s_name, ', ') AS suppliers
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.cost_rank = 1
LEFT JOIN supplier sp ON sp.s_suppkey = l.l_suppkey
LEFT JOIN nation r ON sp.s_nationkey = r.n_nationkey
WHERE l.l_quantity > 100 AND l.l_discount BETWEEN 0.1 AND 0.3
GROUP BY p.p_partkey, p.p_name, r.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) 
                                                           FROM lineitem 
                                                           WHERE l_shipdate >= '1997-01-01')
ORDER BY total_revenue DESC, p.p_name
LIMIT 10;
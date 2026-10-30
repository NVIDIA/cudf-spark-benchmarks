WITH  RevenueCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_price,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COALESCE(MAX(s.s_acctbal), 0) AS max_supplier_balance,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    COUNT(DISTINCT CASE WHEN r.r_name IS NOT NULL THEN s.s_suppkey END) AS supplier_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size > 10 AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_orders DESC
LIMIT 100;
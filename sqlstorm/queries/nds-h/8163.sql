WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = 'EUROPE'
    GROUP BY p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        revenue 
    FROM RankedParts 
    WHERE rn <= 10
)
SELECT 
    t.p_partkey, 
    t.p_name, 
    t.revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity
FROM TopParts t
JOIN lineitem l ON t.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'F'
GROUP BY t.p_partkey, t.p_name, t.revenue
ORDER BY revenue DESC;

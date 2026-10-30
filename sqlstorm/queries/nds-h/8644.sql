WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopRevenue AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        r.revenue
    FROM RankedOrders r
    JOIN orders o ON r.o_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE r.rn = 1
)
SELECT 
    tr.o_orderkey,
    tr.o_orderdate,
    tr.c_name,
    tr.revenue,
    p.p_name,
    s.s_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM TopRevenue tr
JOIN lineitem l ON tr.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    tr.o_orderkey, 
    tr.o_orderdate, 
    tr.c_name, 
    tr.revenue, 
    p.p_name, 
    s.s_name
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    tr.revenue DESC
LIMIT 10;
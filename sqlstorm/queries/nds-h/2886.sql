WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(l.l_linenumber) AS total_lines
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    COALESCE(rk.s_name, 'No Suppliers') AS top_supplier,
    tls.total_quantity,
    tls.total_lines
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrderStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN RankedSuppliers rk ON n.n_nationkey = rk.s_nationkey AND rk.rank = 1
LEFT JOIN TotalLineItems tls ON cs.c_custkey = tls.l_orderkey
WHERE cs.avg_order_value > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
  AND r.r_name IS NOT NULL
ORDER BY total_spent DESC, r.r_name;


WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate < DATE '1998-10-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_supplycost ELSE 0 END) AS total_avail_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    WHERE ps.ps_supplycost IS NOT NULL
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    COALESCE(pss.total_avail_cost, 0) AS total_supplied_cost,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'O') AS open_orders,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN PartSupplierSummary pss ON p.p_partkey = pss.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerSummary cs ON o.o_custkey = cs.c_custkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_size BETWEEN 10 AND 20
AND (r.r_name IS NOT NULL OR s.s_name LIKE '%inc%')
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, pss.total_avail_cost, cs.total_spent, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_supplied_cost DESC, customer_total_spent ASC
LIMIT 10 OFFSET 5;

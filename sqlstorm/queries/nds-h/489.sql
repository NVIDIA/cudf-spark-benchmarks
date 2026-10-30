
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerRanks AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY SUM(o.total_price) DESC) AS rank
    FROM customer c
    JOIN OrderTotals o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT ss.s_name) AS supplier_count,
    COALESCE(AVG(ss.total_avail_qty), 0) AS avg_avail_qty,
    MAX(c.rank) AS max_customer_rank
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN CustomerRanks c ON s.s_suppkey = c.c_custkey
WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
GROUP BY n.n_name
HAVING COUNT(DISTINCT ss.s_name) > 0
ORDER BY n.n_name;

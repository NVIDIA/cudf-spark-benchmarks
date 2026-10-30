WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY c.c_custkey
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(cs.total_spend) AS average_customer_spend,
    sp.part_count,
    sp.total_supply_cost,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_orderpriority
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerSpend cs ON c.c_custkey = cs.c_custkey
LEFT JOIN SupplierPartSummary sp ON sp.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_size > 50))
JOIN RankedOrders ro ON ro.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F')
WHERE n.n_comment IS NOT NULL AND sp.total_supply_cost IS NOT NULL
GROUP BY n.n_name, sp.part_count, sp.total_supply_cost, ro.o_orderkey, ro.o_orderdate, ro.o_orderpriority
HAVING AVG(cs.total_spend) > 1000
ORDER BY n.n_name ASC, total_customers DESC;
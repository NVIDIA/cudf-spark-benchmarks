WITH RankedOrders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate,
           RANK() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS total_ranking
    FROM orders
    WHERE o_orderstatus IN ('O', 'F')
),
FilteredSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal,
           (CASE
               WHEN s_acctbal IS NULL THEN 'No Account'
               WHEN s_acctbal < 5000 THEN 'Low Balance'
               ELSE 'Sufficient Balance'
            END) AS balance_status
    FROM supplier
    WHERE s_acctbal IS NOT NULL OR s_comment IS NOT NULL
),
PartStatistics AS (
    SELECT p_partkey, p_name, p_mfgr, COUNT(ps_supplycost) AS supply_count,
           AVG(ps_supplycost) FILTER (WHERE ps_supplycost > 10) AS avg_supply_cost,
           MAX(ps_availqty) AS max_avail_qty
    FROM part
    JOIN partsupp ON p_partkey = ps_partkey
    GROUP BY p_partkey, p_name, p_mfgr
),
CustomerOrderCounts AS (
    SELECT c_custkey, COUNT(o_orderkey) AS order_count,
           SUM(o_totalprice) AS total_spent
    FROM customer
    LEFT JOIN orders ON c_custkey = o_custkey
    GROUP BY c_custkey
)
SELECT po.p_partkey, po.p_name, po.p_mfgr, ps.balance_status,
       COALESCE(coc.order_count, 0) AS order_count,
       COALESCE(coc.total_spent, 0) AS total_spent,
       ROW_NUMBER() OVER (PARTITION BY ps.balance_status ORDER BY po.p_retailprice DESC) AS retail_rank
FROM part po
JOIN FilteredSuppliers ps ON po.p_partkey % ps.s_suppkey = 0  
LEFT OUTER JOIN CustomerOrderCounts coc ON coc.order_count > 5 AND po.p_partkey = coc.order_count 
WHERE EXISTS (
    SELECT 1
    FROM RankedOrders ro
    WHERE ro.o_orderkey = (SELECT MIN(o_orderkey) FROM orders WHERE o_orderdate >= '1997-01-01')
    AND ro.total_ranking <= 10
)
ORDER BY po.p_partkey, ps.balance_status, retail_rank DESC;
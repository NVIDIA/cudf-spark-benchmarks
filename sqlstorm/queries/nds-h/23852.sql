
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            ELSE 'Balance: ' || CAST(c.c_acctbal AS STRING)
        END AS acct_bal_status,
        n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_mktsegment IN ('BUILDING', 'FURNITURE')
        AND (c.c_acctbal IS NOT NULL OR c.c_acctbal < 1000)
)
SELECT 
    p.p_name,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    COUNT(DISTINCT fc.c_custkey) AS active_customers,
    sc.total_supply_cost
FROM part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN RankedOrders ro ON li.l_orderkey = ro.o_orderkey AND ro.order_rank <= 5
LEFT JOIN FilteredCustomers fc ON fc.c_custkey = li.l_suppkey
JOIN SupplierCost sc ON sc.ps_partkey = p.p_partkey
WHERE p.p_retailprice > 20.00
GROUP BY p.p_name, sc.total_supply_cost
HAVING COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) > (SELECT AVG(total_revenue) FROM (
                                SELECT 
                                    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
                                FROM lineitem li
                                GROUP BY li.l_partkey
                            ) AS avg_revenue)
ORDER BY total_revenue DESC
LIMIT 10 OFFSET 0;


WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    )
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
MaxSupplierCost AS (
    SELECT 
        ps.ps_suppkey, 
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
)
SELECT 
    ns.n_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(cs.total_spent) AS avg_customer_spent,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    CASE 
        WHEN SUM(li.l_extendedprice * (1 - li.l_discount)) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Recorded'
    END AS revenue_status
FROM lineitem li
JOIN RankedOrders ro ON li.l_orderkey = ro.o_orderkey
JOIN CustomerSummary cs ON cs.order_count > 1
JOIN supplier s ON s.s_suppkey = li.l_suppkey
JOIN nation ns ON ns.n_nationkey = s.s_nationkey
LEFT JOIN MaxSupplierCost msc ON msc.ps_suppkey = s.s_suppkey
WHERE li.l_shipdate >= DATE '1998-10-01' - INTERVAL '90 days'
AND ns.n_name IS NOT NULL
GROUP BY ns.n_name
ORDER BY total_revenue DESC
LIMIT 10;

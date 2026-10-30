
WITH  SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
), 
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
MaxRevenue AS (
    SELECT 
        MAX(total_revenue) AS max_revenue
    FROM SupplierRevenue
),
ActiveCustomers AS (
    SELECT 
        co.c_custkey
    FROM CustomerOrderCounts co
    WHERE co.order_count > (
        SELECT AVG(order_count) 
        FROM CustomerOrderCounts
    )
)
SELECT 
    p.p_name,
    s.s_name,
    COALESCE(p.p_type, 'UNKNOWN') AS part_type,
    COUNT(DISTINCT ac.c_custkey) AS active_customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    p.p_retailprice * (1 + COALESCE(NULLIF(SUM(l.l_discount), 0), 0.1)) AS adjusted_price
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN ActiveCustomers ac ON ac.c_custkey = l.l_orderkey
WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
AND EXISTS (
    SELECT 1 FROM MaxRevenue 
    WHERE MaxRevenue.max_revenue > 1000
)
GROUP BY p.p_name, s.s_name, p.p_type, p.p_retailprice
HAVING COUNT(DISTINCT l.l_orderkey) > 5 
OR SUM(l.l_quantity) IS NULL
ORDER BY active_customer_count DESC, adjusted_price DESC;

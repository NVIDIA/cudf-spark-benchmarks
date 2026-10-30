WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    AVG(order_stats.total_spent) AS average_customer_spending,
    MAX(part_costs.total_cost) AS max_part_supply_cost
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN CustomerOrders order_stats ON order_stats.c_custkey = c.c_custkey
JOIN SupplierPartCosts part_costs ON part_costs.ps_partkey = l.l_partkey
WHERE o.o_orderstatus IN ('O', 'F')
  AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
ORDER BY total_revenue DESC, unique_customers DESC;
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
DiscountedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_total
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1996-01-01' 
    AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(d.discounted_total, 0)) AS total_discounted_sales,
    AVG(s.total_supply_cost) AS avg_supply_cost,
    MAX(o.o_totalprice) AS max_order_price
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN DiscountedLineItems d ON o.o_orderkey = d.l_orderkey
LEFT JOIN SupplierSummary s ON s.part_count > 10
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_discounted_sales DESC, max_order_price DESC
LIMIT 10;
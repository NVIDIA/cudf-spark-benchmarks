
WITH  sales_data AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(sd.total_sales), 0) AS total_sales,
    COALESCE(AVG(ss.total_supply_cost), 0) AS avg_supply_cost,
    COALESCE(hvc.total_spent, 0) AS total_spent_by_customer
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN sales_data sd ON o.o_orderkey = sd.o_orderkey
LEFT JOIN supplier_summary ss ON c.c_nationkey = ss.s_suppkey
LEFT JOIN high_value_customers hvc ON c.c_custkey = hvc.c_custkey
GROUP BY c.c_name, hvc.total_spent
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC, order_count DESC;

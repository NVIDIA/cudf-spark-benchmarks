WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > '1996-01-01'
),
filtered_lineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY l.l_orderkey
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            ELSE CASE 
                WHEN s.s_acctbal > 5000 THEN 'High Value'
                ELSE 'Low Value'
            END 
        END AS supplier_value
    FROM supplier s
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS num_of_customers,
    SUM(li.total_revenue) AS total_revenue_from_high_value_suppliers,
    MAX(o.o_totalprice) AS max_order_value,
    MIN(NULLIF(o.o_orderdate, '1997-01-01')) AS first_order_date_not_1997
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN ranked_orders o ON c.c_custkey = o.o_orderkey
LEFT JOIN filtered_lineitems li ON o.o_orderkey = li.l_orderkey
LEFT JOIN supplier_info s ON s.s_suppkey = li.unique_suppliers 
WHERE (s.s_acctbal IS NULL OR s.s_acctbal > 3000)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
   OR SUM(li.total_revenue) > 10000
ORDER BY r.r_name;
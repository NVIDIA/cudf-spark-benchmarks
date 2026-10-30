WITH  ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
),
supplier_availability AS (
    SELECT 
        ps.ps_supplycost,
        ps.ps_availqty,
        p.p_name,
        CASE 
            WHEN ps.ps_availqty < 100 THEN 'Low Stock' 
            ELSE 'In Stock' 
        END as stock_status
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
high_value_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) as total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > 100000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) as order_count,
        SUM(o.o_totalprice) as total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    ra.o_orderkey,
    ra.o_orderdate,
    s.stock_status,
    na.n_name,
    na.total_balance
FROM customer_orders co
LEFT JOIN ranked_orders ra ON co.order_count > 10
LEFT JOIN supplier_availability s ON co.c_custkey = s.ps_supplycost
INNER JOIN high_value_nations na ON co.c_custkey = na.n_nationkey 
WHERE 
    COALESCE(s.ps_availqty, 0) > 0 
    AND na.total_balance IS NOT NULL 
ORDER BY 
    co.total_spent DESC, 
    ra.o_orderdate ASC
LIMIT 50;
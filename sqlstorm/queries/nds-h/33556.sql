WITH  ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
),
supp_part AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand,
        p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_ranked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS account_rank
    FROM customer c
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    sp.p_name,
    sp.p_brand,
    c.c_name AS customer_name,
    CASE 
        WHEN r.o_orderpriority = 'HIGH' THEN 'Priority Order'
        ELSE 'Regular Order'
    END AS order_type,
    COALESCE((SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = r.o_orderkey AND l.l_returnflag = 'R'), 0) AS return_count
FROM ranked_orders r
LEFT JOIN lineitem l ON r.o_orderkey = l.l_orderkey
JOIN supp_part sp ON l.l_partkey = sp.ps_partkey
JOIN customer_ranked c ON r.o_orderkey % c.c_custkey = 0
WHERE sp.ps_supplycost < r.o_totalprice * 0.5
AND r.order_rank <= 10
ORDER BY r.o_orderdate DESC, r.o_totalprice ASC;
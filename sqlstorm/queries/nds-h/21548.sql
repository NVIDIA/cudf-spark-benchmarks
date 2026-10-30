WITH RecursivePartData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice) DESC) AS rank_within_type
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.rank_within_type,
        COALESCE(AVG(s.s_acctbal), 0) AS avg_supplier_balance
    FROM RecursivePartData p
    LEFT JOIN supplier s ON p.supplier_count > 0
    WHERE p.rank_within_type <= 5
    GROUP BY p.p_partkey, p.p_name, p.rank_within_type
), CustomerData AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.rank_within_type,
    f.avg_supplier_balance,
    c.c_custkey,
    c.order_count,
    c.max_order_value,
    c.total_filled_orders,
    CASE 
        WHEN c.total_filled_orders IS NULL THEN 'No Orders'
        WHEN c.total_filled_orders > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM FilteredParts f
FULL OUTER JOIN CustomerData c ON f.rank_within_type = c.order_count
WHERE (f.avg_supplier_balance > 0 OR c.total_filled_orders IS NOT NULL)
ORDER BY f.p_partkey DESC NULLS LAST, c.c_custkey ASC;

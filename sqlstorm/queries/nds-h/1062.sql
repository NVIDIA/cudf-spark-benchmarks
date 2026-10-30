WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_clerk,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate > DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerBalance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS balance_status
    FROM customer c
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    cs.c_name AS customer_name,
    ss.s_suppkey AS supplier_key,
    ss.total_cost,
    cs.balance_status,
    COALESCE((
        SELECT COUNT(*)
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'R'
    ), 0) AS returned_item_count
FROM RankedOrders o
LEFT JOIN CustomerBalance cs ON o.o_orderkey = cs.c_custkey
LEFT JOIN SupplierStats ss ON ss.part_count > 10 AND ss.total_cost > 5000
WHERE o.rnk = 1
  AND o.o_orderstatus = 'F'
ORDER BY o.o_orderdate DESC, ss.total_cost DESC;
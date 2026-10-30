
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
MaxSupplierContribution AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartNationDetails AS (
    SELECT p.p_partkey, p.p_name, n.n_name, r.r_name,
           COALESCE(NULLIF(p.p_comment, ''), 'No comment') AS p_comment
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size BETWEEN 1 AND 10 AND r.r_name IS NOT NULL
),
OrderLineDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
           COUNT(l.l_orderkey) AS line_item_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND DATE '1998-10-01'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    rn.s_name,
    rn.rank,
    co.total_spent,
    COALESCE(ol.net_value, 0) AS total_order_value,
    CASE 
        WHEN co.total_spent IS NOT NULL THEN 'High Roller'
        ELSE 'Casual Buyer'
    END AS customer_type
FROM PartNationDetails p
JOIN RankedSuppliers rn ON p.p_partkey = rn.s_suppkey
LEFT JOIN CustomerOrders co ON rn.s_nationkey = co.c_custkey
LEFT JOIN OrderLineDetails ol ON ol.o_orderkey = co.c_custkey
WHERE (rn.rank = 1 AND co.total_spent IS NOT NULL)
   OR (COALESCE(ol.net_value, 0) > 5000 AND p.p_comment IS NOT NULL)
ORDER BY p.p_partkey, rn.rank DESC;

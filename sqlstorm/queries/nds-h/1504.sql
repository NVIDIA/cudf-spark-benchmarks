WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus <> 'F'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank_cust
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT
    rp.p_name,
    rp.p_brand,
    rp.total_cost,
    COALESCE(hvc.c_name, 'No High Value Customer') AS high_value_customer_name,
    COALESCE(hvc.c_acctbal, 0) AS high_value_customer_balance,
    COALESCE(co.total_revenue, 0) AS customer_total_revenue
FROM RankedParts rp
LEFT JOIN HighValueCustomers hvc ON rp.p_partkey = hvc.c_custkey
LEFT JOIN CustomerOrders co ON hvc.c_custkey = co.c_custkey
WHERE rp.rnk <= 5
    AND rp.total_cost > (
        SELECT AVG(total_cost) FROM RankedParts
    )
ORDER BY rp.total_cost DESC, high_value_customer_balance DESC;

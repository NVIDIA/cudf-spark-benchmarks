WITH CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM
        CustomerOrders
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    s.s_name AS supplier_name,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    COALESCE(TC.order_count, 0) AS number_of_orders,
    COALESCE(TC.total_spent, 0) AS total_spent_by_customer
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN
    TopCustomers TC ON TC.c_custkey = s.s_nationkey
WHERE
    (p.p_size > 10 AND s.s_acctbal > 1000) OR
    (p.p_type LIKE '%metal%' AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp))
ORDER BY
    p.p_partkey,
    spending_rank ASC NULLS LAST;

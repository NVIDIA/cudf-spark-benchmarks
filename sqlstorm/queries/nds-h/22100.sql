WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_nationkey
),
LowSaleCustomers AS (
    SELECT
        cus.c_custkey,
        cus.c_name,
        CASE
            WHEN cus.total_spent IS NULL THEN 'No Orders'
            WHEN cus.total_spent = 0 THEN 'No Spending'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM
        CustomerOrderSummary cus
    WHERE
        cus.total_orders < 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    AVG(CASE 
            WHEN l.l_discount = 0 THEN p.p_retailprice 
            ELSE p.p_retailprice * (1 - l.l_discount)
        END) AS avg_discounted_price,
    COALESCE(rn.total_available_qty, 0) AS available_qty,
    lc.customer_type,
    COUNT(DISTINCT o.o_orderkey) AS orders_count
FROM
    part p
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN
    RankedSuppliers rn ON l.l_suppkey = rn.s_suppkey AND rn.supplier_rank <= 5
LEFT JOIN
    LowSaleCustomers lc ON o.o_custkey = lc.c_custkey
WHERE
    (p.p_size > 10 OR p.p_brand LIKE 'A%')
    AND (lc.customer_type <> 'No Orders' OR lc.customer_type IS NULL)
GROUP BY
    p.p_partkey, p.p_name, p.p_brand, lc.customer_type, rn.total_available_qty
HAVING
    COUNT(DISTINCT o.o_orderkey) > 1
ORDER BY
    avg_discounted_price DESC, p.p_name;

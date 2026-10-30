WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.p_type) AS total_parts
    FROM
        part p
),
SupplierAvailability AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(s.s_acctbal) AS max_supplier_acctbal
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM
        customerOrders co
    JOIN
        customer c ON co.c_custkey = c.c_custkey
)

SELECT
    rp.p_name,
    rp.p_retailprice,
    sa.total_avail_qty,
    sa.max_supplier_acctbal,
    tc.c_name AS top_customer,
    tc.total_spent AS customer_spending,
    CASE 
        WHEN tc.order_count > 10 THEN 'High Roller'
        WHEN tc.order_count BETWEEN 5 AND 10 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_segment
FROM
    RankedParts rp
LEFT JOIN
    SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
LEFT JOIN
    TopCustomers tc ON tc.customer_rank <= 10
WHERE
    rp.rn = 1
    AND (sa.total_avail_qty IS NOT NULL OR sa.max_supplier_acctbal IS NOT NULL)
ORDER BY
    rp.p_retailprice DESC, tc.total_spent DESC;

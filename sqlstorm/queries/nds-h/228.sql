WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        co.total_orders,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM
        customer c
    JOIN
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT
    tc.c_custkey,
    tc.c_name,
    tc.total_orders,
    tc.total_spent,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    COALESCE(rs.s_acctbal, 0) AS supplier_acctbal
FROM
    TopCustomers tc
LEFT JOIN
    RankedSuppliers rs ON rs.rn = 1
WHERE
    tc.rank <= 10 
    AND EXISTS (
        SELECT 1
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE
            o.o_custkey = tc.c_custkey
            AND l.l_discount > 0.05
            AND l.l_tax < 0.1
    )
ORDER BY
    tc.total_spent DESC;

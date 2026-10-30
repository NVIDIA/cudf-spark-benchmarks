WITH SupplierRevenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM
        customer c
    JOIN
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT
    t_s.supplier_rank,
    t_s.s_name AS supplier_name,
    t_c.customer_rank,
    t_c.c_name AS customer_name,
    sr.total_revenue,
    co.total_orders,
    co.total_spent
FROM
    TopSuppliers t_s
FULL OUTER JOIN
    TopCustomers t_c ON t_s.supplier_rank = t_c.customer_rank
LEFT JOIN
    SupplierRevenue sr ON t_s.s_suppkey = sr.s_suppkey
LEFT JOIN
    CustomerOrders co ON t_c.c_custkey = co.c_custkey
WHERE
    (sr.total_revenue > 100000 OR sr.total_revenue IS NULL)
    AND (co.total_orders > 5 OR co.total_orders IS NULL)
ORDER BY 
    t_s.supplier_rank, t_c.customer_rank;

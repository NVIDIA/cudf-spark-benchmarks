WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
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
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    rp.p_name,
    ts.s_name AS top_supplier,
    co.c_name AS top_customer,
    rp.total_cost,
    ts.total_available,
    co.total_orders,
    co.total_spent
FROM
    RankedParts rp
JOIN
    TopSuppliers ts ON ts.supplier_rank = 1
JOIN
    CustomerOrders co ON co.total_orders = (SELECT MAX(total_orders) FROM CustomerOrders)
WHERE
    rp.rank <= 5
ORDER BY
    rp.total_cost DESC, ts.total_available DESC;

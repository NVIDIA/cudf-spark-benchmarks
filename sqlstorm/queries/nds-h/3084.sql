WITH RankedSales AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        COUNT(o.o_orderkey) > 2
)
SELECT
    r.r_name,
    SUM(t.total_sales) AS total_revenue,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    MAX(ts.total_supply_cost) AS max_supplier_cost
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    customerOrders co ON co.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '90 days')
LEFT JOIN
    RankedSales t ON t.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IS NOT NULL)
LEFT JOIN
    TopSuppliers ts ON ts.s_suppkey IN (SELECT DISTINCT l.l_suppkey FROM lineitem l WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days')
WHERE
    r.r_name LIKE 'N%'
GROUP BY
    r.r_name
HAVING
    SUM(t.total_sales) > 10000
ORDER BY
    total_revenue DESC;
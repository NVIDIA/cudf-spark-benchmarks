WITH CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS number_of_orders
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
)
SELECT
    p.p_name,
    p.p_brand,
    COALESCE(po.total_spent, 0) AS customer_total_spent,
    ps.total_available AS supplier_total_available,
    ps.average_cost,
    COUNT(DISTINCT l.l_orderkey) AS number_of_sales,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sale_price
FROM
    part p
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    CustomerOrders po ON po.c_custkey IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal > 1000
    )
WHERE
    p.p_size > 10 AND
    (p.p_container LIKE 'SMALL%' OR ps.average_cost IS NULL)
GROUP BY
    p.p_partkey, p.p_name, p.p_brand, po.total_spent, ps.total_available, ps.average_cost
HAVING
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY
    customer_total_spent DESC, number_of_sales DESC;

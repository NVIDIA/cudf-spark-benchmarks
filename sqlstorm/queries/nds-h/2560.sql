
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'F' 
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 10000
)

SELECT
    p.p_name,
    p.p_type,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    COALESCE(RS.s_acctbal, 0) AS supplier_acctbal,
    HVC.c_name AS high_value_customer,
    HVC.total_spent
FROM
    part p
LEFT JOIN
    RankedSuppliers RS ON RS.rn = 1 AND p.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        GROUP BY ps.ps_partkey
        HAVING SUM(ps.ps_availqty) > 50
    )
LEFT JOIN
    HighValueCustomers HVC ON p.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'F'
    )
WHERE
    p.p_retailprice BETWEEN 10.00 AND 500.00
AND
    (p.p_size IS NULL OR p.p_size IN (1, 2, 3))
ORDER BY
    p.p_name, supplier_acctbal DESC, total_spent DESC
LIMIT 50;

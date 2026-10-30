
WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_in_nation
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'F'
    GROUP BY
        c.c_custkey, c.c_name, c.c_nationkey
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT
    cs.c_name,
    ss.s_name,
    ss.total_cost,
    cs.total_spent
FROM
    CustomerOrders cs
LEFT JOIN
    FilteredSuppliers fs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany') LIMIT 1)
JOIN
    SupplierStats ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_size BETWEEN 10 AND 20
        AND p.p_retailprice > 100.00
        ORDER BY ps.ps_availqty DESC
        LIMIT 1
    )
WHERE
    cs.rank_in_nation <= 5
ORDER BY
    cs.total_spent DESC;

WITH SupplierCosts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        SUM(ps.ps_availqty) AS total_availqty
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM
        part p
    WHERE
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    r.r_name,
    n.n_name,
    p.p_name,
    p.p_brand,
    sc.total_supplycost,
    sc.total_availqty,
    co.total_orders,
    co.total_spent
FROM
    region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierCosts sc ON sc.ps_partkey IN (SELECT p_partkey FROM PartDetails WHERE rn = 1)
LEFT JOIN PartDetails p ON p.p_partkey = sc.ps_partkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_custkey
WHERE
    (co.total_orders > 5 OR co.total_spent > 1000)
    AND r.r_name IS NOT NULL
ORDER BY
    r.r_name, n.n_name, p.p_brand;

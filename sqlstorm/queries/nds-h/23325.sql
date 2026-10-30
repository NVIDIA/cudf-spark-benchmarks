
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        CASE
            WHEN SUM(o.o_totalprice) > 10000 THEN 'High'
            WHEN SUM(o.o_totalprice) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice)
            FROM part p2
            WHERE p2.p_size IS NOT NULL
        )
    GROUP BY
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
)
SELECT
    p.p_name,
    p.p_brand,
    h.total_spent,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    CASE WHEN p.supplier_count > 0 THEN 'Available' ELSE 'Unavailable' END AS availability_status
FROM
    FilteredParts p
LEFT JOIN
    RankedSuppliers s ON p.p_partkey = s.s_suppkey
JOIN
    HighValueCustomers h ON h.c_custkey = (
        SELECT c.c_custkey
        FROM customer c
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
WHERE
    (p.p_name LIKE '%the%' OR p.p_brand LIKE '%super%')
    AND (s.rank IS NULL OR s.rank <= 3)
    AND (h.customer_value = 'High' OR h.customer_value = 'Medium')
ORDER BY
    p.p_name, availability_status DESC, h.total_spent DESC;

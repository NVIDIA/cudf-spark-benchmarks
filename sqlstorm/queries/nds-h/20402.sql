
WITH CTE_SupplierPrices AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey
),
CTE_NationSummary AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
),
CTE_Orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderstatus
),
CTE_BigSpendSuppliers AS (
    SELECT
        sp.s_suppkey,
        sp.total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY sp.total_supplycost ORDER BY sp.total_supplycost DESC) AS rn
    FROM
        CTE_SupplierPrices sp
    WHERE
        sp.total_supplycost > (SELECT AVG(total_supplycost) FROM CTE_SupplierPrices)
)
SELECT
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_acctbal,
    sp.total_supplycost AS supplier_total_cost,
    ord.o_orderkey,
    ord.o_orderstatus,
    ord.revenue
FROM
    CTE_NationSummary ns
LEFT JOIN
    CTE_BigSpendSuppliers sp ON ns.supplier_count = sp.rn
LEFT JOIN
    CTE_Orders ord ON sp.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_type LIKE '%widget%' 
            ORDER BY p.p_retailprice ASC 
            LIMIT 1
        ) 
        LIMIT 1
    )
WHERE 
    (ns.total_acctbal > 50000 OR ns.total_acctbal IS NULL)
    AND sp.total_supplycost IS NOT NULL
ORDER BY
    ns.n_name, ord.revenue DESC
LIMIT 100
OFFSET 10;
